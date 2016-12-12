# frozen_string_literal: true
require 'sprockets_test'
require 'sprockets/bundle'
require 'sprockets/source_map_utils'

silence_warnings do
  require 'sass'
end

class TestSourceMaps < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(fixture_path('source-maps')) do |env|
      env.append_path('.')
      env.cache = {}
    end
  end

  def get_sources(map)
    map["sections"].reduce([]) { |r, s| r | s["map"]["sources"] }
  end

  test "builds a source map for js files" do
    asset = @env['child.js']
    map = asset.metadata[:map]
    assert_equal ["child.source.js"], get_sources(map)
  end

  test "builds a concatenated source map" do
    asset = @env['application.js']
    map = asset.metadata[:map]
    assert_equal [
      "project.source.coffee",
      "users.source.coffee",
      "application.source.coffee"
    ], get_sources(map)
  end

  test "builds a minified source map" do
    @env.js_compressor = Sprockets::UglifierCompressor.new
    

    asset = @env['application.js']
    map = Sprockets::SourceMapUtils.decode_source_map(asset.metadata[:map])
    assert map[:mappings].all? { |mapping| mapping[:generated][0] == 1 }
    assert_equal [
      "project.source.coffee",
      "users.source.coffee",
      "application.source.coffee"
    ], map[:sources]
  end

  test "builds a source map with js dependency" do
    asset = @env['parent.js']
    map = asset.metadata[:map]
    assert_equal [
      "child.source.js",
      "users.source.coffee",
      "parent.source.js"
    ], get_sources(map)
  end

  test "rebuilds a source map when related dependency has changed" do
    filename = fixture_path('source-maps/dynamic/unstable.js')
    sandbox filename do
      write(filename, "var magic_number = 42;", 1421000000)
      asset1  = @env.find_asset('dynamic/application.js', pipeline: :debug)
      mapUrl1 = asset1.source.match(/^\/\/# sourceMappingURL=(.*?)$/)[1]

      write(filename, "var number_of_the_beast = 666;\nmagic_number = 7;", 1422000000)
      asset2  = @env.find_asset('dynamic/application.js', pipeline: :debug)
      mapUrl2 = asset2.source.match(/^\/\/# sourceMappingURL=(.*?)$/)[1]

      refute_equal(asset1.digest_path, asset2.digest_path, "Asset digest didn't update.")
      refute_equal(mapUrl1, mapUrl2, "`sourceMappingUrl` didn't update.")
    end
  end

  test "compile coffeescript source map" do
    assert asset = @env.find_asset("coffee/main.js")
    assert_equal fixture_path('source-maps/coffee/main.coffee'), asset.filename
    assert_equal "application/javascript", asset.content_type

    assert_match "(function() {", asset.source
    assert_match "Math.sqrt", asset.source

    assert asset = @env.find_asset("coffee/main.js.map")
    assert_equal fixture_path('source-maps/coffee/main.coffee'), asset.filename
    assert_equal "coffee/main.js.map", asset.logical_path
    assert_equal "application/js-sourcemap+json", asset.content_type
    assert_equal [
      "file://#{fixture_path_for_uri('source-maps/coffee/main.coffee')}?type=text/coffeescript&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "coffee/main.coffee",
      "sections" => [
        {
          "offset" => { "line" => 0, "column" => 0 },
          "map"    => {
            "version"  => 3,
            "file"     => "coffee/main.coffee",
            "mappings" => "AACA;AAAA,MAAA,sDAAA;IAAA;;EAAA,MAAA,GAAW;;EACX,QAAA,GAAW;;EAGX,IAAgB,QAAhB;IAAA,MAAA,GAAS,CAAC,GAAV;;;EAGA,MAAA,GAAS,SAAC,CAAD;WAAO,CAAA,GAAI;EAAX;;EAGT,IAAA,GAAO,CAAC,CAAD,EAAI,CAAJ,EAAO,CAAP,EAAU,CAAV,EAAa,CAAb;;EAGP,IAAA,GACE;IAAA,IAAA,EAAQ,IAAI,CAAC,IAAb;IACA,MAAA,EAAQ,MADR;IAEA,IAAA,EAAQ,SAAC,CAAD;aAAO,CAAA,GAAI,MAAA,CAAO,CAAP;IAAX,CAFR;;;EAKF,IAAA,GAAO,SAAA;AACL,QAAA;IADM,uBAAQ;WACd,KAAA,CAAM,MAAN,EAAc,OAAd;EADK;;EAIP,IAAsB,8CAAtB;IAAA,KAAA,CAAM,YAAN,EAAA;;;EAGA,KAAA;;AAAS;SAAA,sCAAA;;mBAAA,IAAI,CAAC,IAAL,CAAU,GAAV;AAAA;;;AA1BT",
            "sources"  => ["main.source.coffee"],
            "names"    => []
          }
        }
      ]
    }, map)
  end

  test "use precompiled coffeescript source map" do
    assert asset = @env.find_asset("coffee/precompiled/main.js")
    assert_equal fixture_path('source-maps/coffee/precompiled/main.js'), asset.filename
    assert_equal "application/javascript", asset.content_type

    assert_match "(function() {", asset.source
    assert_match "Math.sqrt", asset.source

    assert asset = @env.find_asset("coffee/precompiled/main.js.map")
    assert_equal fixture_path('source-maps/coffee/precompiled/main.js.map'), asset.filename
    assert_equal "coffee/precompiled/main.js.map", asset.logical_path
    assert_equal "application/js-sourcemap+json", asset.content_type

    assert map = JSON.parse(asset.source)
    assert_equal 3, map['version']
    assert_equal "main.js", map['file']
    assert_equal 779, map['mappings'].size
  end

  test "compile babel source map" do
    assert asset = @env.find_asset("babel/main.js")
    assert_equal fixture_path('source-maps/babel/main.es6'), asset.filename
    assert_equal "application/javascript", asset.content_type

    assert_match "var SkinnedMesh = (function (_THREE$Mesh)", asset.source
    assert_match "_defineProperty({}, Symbol.iterator", asset.source

    assert asset = @env.find_asset("babel/main.js.map")
    assert_equal fixture_path('source-maps/babel/main.es6'), asset.filename
    assert_equal "babel/main.js.map", asset.logical_path
    assert_equal "application/js-sourcemap+json", asset.content_type
    assert_equal [
      "file://#{fixture_path_for_uri('source-maps/babel/main.es6')}?type=application/ecmascript-6&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "babel/main.es6",
      "sections" => [
        {
          "offset" => { "line" => 0, "column" => 0 },
          "map"    => {
            "version"  => 3,
            "file"     => "babel/main.es6",
            "mappings" => ";;;;;;;;;;AACA,IAAI,IAAI,GAAG,KAAK,CAAC,GAAG,CAAC,UAAA,CAAC;SAAI,CAAC,GAAG,CAAC;CAAA,CAAC,CAAC;AACjC,IAAI,IAAI,GAAG,KAAK,CAAC,GAAG,CAAC,UAAC,CAAC,EAAE,CAAC;SAAK,CAAC,GAAG,CAAC;CAAA,CAAC,CAAC;;IAEhC,WAAW;YAAX,WAAW;;AACJ,WADP,WAAW,CACH,QAAQ,EAAE,SAAS,EAAE;0BAD7B,WAAW;;AAEb,+BAFE,WAAW,6CAEP,QAAQ,EAAE,SAAS,EAAE;GAE5B;;eAJG,WAAW;;WAKT,gBAAC,MAAM,EAAE;AACb,iCANE,WAAW,wCAME;KAChB;;;WACmB,yBAAG;AACrB,aAAO,IAAI,KAAK,CAAC,OAAO,EAAE,CAAC;KAC5B;;;SAVG,WAAW;GAAS,KAAK,CAAC,IAAI;;AAapC,IAAI,SAAS,uBACV,MAAM,CAAC,QAAQ,0BAAG;MACb,GAAG,EAAM,GAAG,EAEV,IAAI;;;;AAFN,WAAG,GAAG,CAAC,EAAE,GAAG,GAAG,CAAC;;;AAEd,YAAI,GAAG,GAAG;;AACd,WAAG,GAAG,GAAG,CAAC;AACV,WAAG,IAAI,IAAI,CAAC;;eACN,GAAG;;;;;;;;;;;CAEZ,EACF,CAAA",
            "sources"  => ["main.source.es6"],
            "names"    => []
          }
        }
      ]
    }, map)
  end

  test "use precompiled babel source map" do
    assert asset = @env.find_asset("babel/precompiled/main.js")
    assert_equal fixture_path('source-maps/babel/precompiled/main.js'), asset.filename
    assert_equal "application/javascript", asset.content_type

    assert_match "var SkinnedMesh = (function (_THREE$Mesh)", asset.source
    assert_match "_defineProperty({}, Symbol.iterator", asset.source

    assert asset = @env.find_asset("babel/precompiled/main.js.map")
    assert_equal fixture_path('source-maps/babel/precompiled/main.js.map'), asset.filename
    assert_equal "babel/precompiled/main.js.map", asset.logical_path
    assert_equal "application/js-sourcemap+json", asset.content_type

    assert map = JSON.parse(asset.source)
    assert_equal 3, map['version']
    assert_equal "main.es6", map['file']
    assert_equal 694, map['mappings'].size
  end

  test "compile scss source map" do
    asset = silence_warnings do
      @env.find_asset("sass/main.css")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/main.scss'), asset.filename
    assert_equal "text/css", asset.content_type

    assert_match "nav a {", asset.source

    asset = silence_warnings do
      @env.find_asset("sass/main.css.map")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/main.scss'), asset.filename
    assert_equal "sass/main.css.map", asset.logical_path
    assert_equal "application/css-sourcemap+json", asset.content_type
    assert_equal [
      "file://#{fixture_path_for_uri('source-maps/sass/main.scss')}?type=text/scss&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "sass/main.scss",
      "sections" => [
        {
          "offset" => { "line" => 0, "column" => 0 },
          "map"    => {
            "version"  => 3,
            "file"     => "sass/main.scss",
            "mappings" => "AACE,MAAG;EACD,MAAM,EAAE,CAAC;EACT,OAAO,EAAE,CAAC;EACV,UAAU,EAAE,IAAI;AAGlB,MAAG;EAAE,OAAO,EAAE,YAAY;AAE1B,KAAE;EACA,OAAO,EAAE,KAAK;EACd,OAAO,EAAE,QAAQ;EACjB,eAAe,EAAE,IAAI",
            "sources"  => ['main.source.scss'],
            "names"    => []
          }
        }
      ]
    }, map)
  end

  test "compile scss source map with imported dependencies" do
    asset = silence_warnings do
      @env.find_asset("sass/with-import.css")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/with-import.scss'), asset.filename
    assert_equal "text/css", asset.content_type

    assert_match "body {\n  color: red; }", asset.source

    asset = silence_warnings do
      @env.find_asset("sass/with-import.css.map")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/with-import.scss'), asset.filename
    assert_equal "sass/with-import.css.map", asset.logical_path
    assert_equal "application/css-sourcemap+json", asset.content_type
    assert_equal [
      "file://#{fixture_path_for_uri('source-maps/sass/_imported.scss')}?type=text/scss&pipeline=source",
      "file://#{fixture_path_for_uri('source-maps/sass/with-import.scss')}?type=text/scss&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "sass/with-import.scss",
      "sections" => [
        {
          "offset" => { "line" => 0, "column" => 0 },
          "map"    => {
            "version"  => 3,
            "file"     => "sass/with-import.scss",
            "mappings" => "AAAA,IAAK;EAAE,KAAK,EAAE,GAAG;;ACEjB,GAAI;EAAE,KAAK,EAAE,IAAI",
            "sources"  => [
              "_imported.source.scss",
              "with-import.source.scss"
            ],
            "names"    => []
          }
        }
      ]
    }, map)
  end

  test "use precompiled scss source map" do
    asset = silence_warnings do
      @env.find_asset("sass/precompiled/main.css")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/precompiled/main.css'), asset.filename
    assert_equal "text/css", asset.content_type

    assert_match "nav a {", asset.source

    asset = silence_warnings do
      @env.find_asset("sass/precompiled/main.css.map")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/precompiled/main.css.map'), asset.filename
    assert_equal "sass/precompiled/main.css.map", asset.logical_path
    assert_equal "application/css-sourcemap+json", asset.content_type

    assert map = JSON.parse(asset.source)
    assert_equal 3, map['version']
    assert_equal "main.css", map['file']
    assert_equal 172, map['mappings'].size
  end

  test "source maps work with index alias" do
    asset = @env.find_asset("foo.js",  pipeline: :debug)
    mapUrl = asset.source.match(/^\/\/# sourceMappingURL=(.*)$/)[1]
    assert_equal "foo/index.js-501c1acd99a6f760dd3ec4195ab25a3518f689fcf1ffc9be33f28e2f28712826.map", mapUrl

    map = JSON.parse(@env.find_asset('foo/index.js.map').source)
    assert_equal [
      "file.source.coffee",
      "index.source.js"
    ], get_sources(map)
  end

  test "relative sources at different depths" do
    assert @env.find_asset("sub/directory.js", pipeline: :debug)
    assert map = JSON.parse(@env.find_asset("sub/directory.js.map").source)
    assert_equal [
      "a.source.js",
      "modules/something.source.js",
      "directory.source.js"
    ], get_sources(map)
  end

  test "source maps are updated correctly after file change" do
    filename = fixture_path('source-maps/sub/a.js')
    sandbox filename do
      expected = JSON.parse(@env.find_asset('sub/directory.js.map').source).tap do |map|
        index = map["sections"].find_index { |s| /sub\/a\.js$/ =~ s["map"]["file"] }
        map["sections"][index]["map"]["mappings"] << ";AACA"
        map["sections"][(index+1)..-1].each do |s|
          s["offset"]["line"] += 1
        end
      end
        
      File.open(filename, 'a') do |file|
        file.puts "console.log('newline');"
      end

      assert_equal JSON.dump(expected), @env.find_asset('sub/directory.js.map').source
    end
  end
end


class TestSasscSourceMaps < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env = Sprockets::Environment.new(".") do |env|
      require 'sprockets/sassc_processor'
      env.register_transformer 'text/sass', 'text/css', Sprockets::SasscProcessor
      env.register_transformer 'text/scss', 'text/css', Sprockets::ScsscProcessor
      env.append_path fixture_path('source-maps')
    end
  end

  test "compile scss source map" do
    asset = silence_warnings do
      @env.find_asset("sass/main.css")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/main.scss'), asset.filename
    assert_equal "text/css", asset.content_type

    assert_match "nav a {", asset.source

    asset = silence_warnings do
      @env.find_asset("sass/main.css.map")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/main.scss'), asset.filename
    assert_equal "sass/main.css.map", asset.logical_path
    assert_equal "application/css-sourcemap+json", asset.content_type
    assert_equal [
      "file:///#{ fixture_path('source-maps/sass/main.scss').sub(/\A\//, '') }?type=text/scss&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "sass/main.scss",
      "sections" => [
        {
          "offset" => { "line" => 0, "column" => 0 },
          "map"    => {
            "version"  => 3,
            "file"     => "sass/main.scss",
            "mappings" => "AAAA,AACE,GADC,CACD,EAAE,CAAC;EACD,MAAM,EAAE,CAAE;EACV,OAAO,EAAE,CAAE;EACX,UAAU,EAAE,IAAK,GAClB;;AALH,AAOE,GAPC,CAOD,EAAE,CAAC;EAAE,OAAO,EAAE,YAAa,GAAI;;AAPjC,AASE,GATC,CASD,CAAC,CAAC;EACA,OAAO,EAAE,KAAM;EACf,OAAO,EAAE,QAAS;EAClB,eAAe,EAAE,IAAK,GACvB",
            "sources"  => ["main.source.scss"],
            "names"    => []
          }
        }
      ]
    }, map)
  end

  test "compile scss source map with imported dependencies" do
    asset = silence_warnings do
      @env.find_asset("sass/with-import.css")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/with-import.scss'), asset.filename
    assert_equal "text/css", asset.content_type

    assert_match "body {\n  color: red; }", asset.source

    asset = silence_warnings do
      @env.find_asset("sass/with-import.css.map")
    end
    assert asset
    assert_equal fixture_path('source-maps/sass/with-import.scss'), asset.filename
    assert_equal "sass/with-import.css.map", asset.logical_path
    assert_equal "application/css-sourcemap+json", asset.content_type
    assert_equal [
      "file://#{fixture_path_for_uri('source-maps/sass/_imported.scss')}?type=text/scss&pipeline=source",
      "file://#{fixture_path_for_uri('source-maps/sass/with-import.scss')}?type=text/scss&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "sass/with-import.scss",
      "sections" => [
        {
          "offset" => { "line" => 0, "column" => 0 },
          "map"    => {
            "version"  => 3,
            "file"     => "sass/with-import.scss",
            "mappings" => "ACAA,AAAA,IAAI,CAAC;EAAE,KAAK,EAAE,GAAI,GAAI;;ADEtB,AAAA,GAAG,CAAC;EAAE,KAAK,EAAE,IAAK,GAAI",
            "sources"  => [
              "with-import.source.scss",
              "_imported.source.scss"
            ],
            "names"    => []
          }
        }
      ]
    }, map)
  end
end
