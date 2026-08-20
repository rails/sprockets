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
    map["sections"].reduce([]) { |r, s| r + s["map"]["sources"] }
  end
  def get_sourcesContent(map)
    map["sections"].reduce([]) { |r, s| r + (s["map"]["sourcesContent"] || s["map"]["sources"].map { nil }) }
  end

  # Offset should be the line that the asset starts on minus one
  test "correct offsets" do
    asset = @env["multi-require.js"]
    map   = asset.metadata[:map]

    child         = @env["child.js"]
    child_lines   = child.to_s.lines.length
    child_section = map["sections"][0]
    assert_equal 0, child_section["offset"]["line"]

    coffee_main         = @env["coffee/main.js"]
    coffee_main_lines   = coffee_main.to_s.lines.length
    coffee_main_section = map["sections"][1]
    assert_equal child_lines, coffee_main_section["offset"]["line"]

    sub_a_js          = @env["sub/a.js"]
    sub_a_js_lines    = sub_a_js.to_s.lines.length
    sub_a_js_section  = map["sections"][2]

    assert_equal coffee_main_lines + child_lines, sub_a_js_section["offset"]["line"]

    plain_js_section = map["sections"][3]
    assert_equal sub_a_js_lines + coffee_main_lines + child_lines, plain_js_section["offset"]["line"]
  end

  test "builds a source map for js files" do
    asset = @env['child.js']
    map = asset.metadata[:map]
    assert_equal ["child.js"], get_sources(map)
    assert_equal [nil], get_sourcesContent(map)
  end

  test "builds a concatenated source map" do
    asset = @env['application.js']
    map = asset.metadata[:map]
    assert_equal [
      "project.coffee",
      "users.coffee",
      "application.coffee"
    ], get_sources(map)
    assert_equal [nil, nil, nil], get_sourcesContent(map)
  end

  test "reads js data transcoded to UTF-8" do
    processor = Proc.new do |input|
      assert_equal Encoding::UTF_8, input[:data].encoding
      { data: input[:data] }
    end
    @env.register_processor('application/javascript', processor)
    assert asset = @env.find_asset('plain.js', pipeline: :debug)
  ensure
    @env.unregister_preprocessor('application/javascript', processor)
  end

  test "reads css data transcoded to UTF-8" do
    processor = Proc.new do |input|
      assert_equal Encoding::UTF_8, input[:data].encoding
      { data: input[:data] }
    end
    @env.register_processor('text/css', processor)
    assert asset = @env.find_asset('sass/precompiled/main.css', pipeline: :debug)
  ensure
    @env.unregister_preprocessor('text/css', processor)
  end

  test "builds a minified source map" do
    @env.js_compressor = Sprockets::UglifierCompressor.new

    asset = @env['application.js']
    map = Sprockets::SourceMapUtils.decode_source_map(asset.metadata[:map])
    assert map[:mappings].all? { |mapping| mapping[:generated][0] == 1 }
    assert_equal [
      "project.coffee",
      "users.coffee",
      "application.coffee"
    ], map[:sources]
    assert_nil map[:sourcesContent]
  end

  test "builds a source map with js dependency" do
    asset = @env['parent.js']
    map = asset.metadata[:map]
    assert_equal [
      "child.js",
      "users.coffee",
      "parent.js"
    ], get_sources(map)
    assert_equal [nil, nil, nil], get_sourcesContent(map)
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
    assert_equal [], normalize_uris(asset.links)

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
            "sources"  => ["main.coffee"],
            "sourcesContent"=>[
              "# Assignment:\n" +
              "number   = 42\n" +
              "opposite = true\n" +
              "\n" +
              "# Conditions:\n" +
              "number = -42 if opposite\n" +
              "\n" +
              "# Functions:\n" +
              "square = (x) -> x * x\n" +
              "\n" +
              "# Arrays:\n" +
              "list = [1, 2, 3, 4, 5]\n" +
              "\n" +
              "# Objects:\n" +
              "math =\n" +
              "  root:   Math.sqrt\n" +
              "  square: square\n" +
              "  cube:   (x) -> x * square x\n" +
              "\n" +
              "# Splats:\n" +
              "race = (winner, runners...) ->\n" +
              "  print winner, runners\n" +
              "\n" +
              "# Existence:\n" +
              "alert \"I knew it!\" if elvis?\n" +
              "\n" +
              "# Array comprehensions:\n" +
              "cubes = (math.cube num for num in list)\n"
            ],
            "names"    => [],
            "x_sprockets_linecount"=>47
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
    assert_equal [], normalize_uris(asset.links)

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
            "sources"  => ["main.es6"],
            "sourcesContent"=>[
              "\n" +
              "var odds = evens.map(v => v + 1);\n" +
              "var nums = evens.map((v, i) => v + i);\n" +
              "\n" +
              "class SkinnedMesh extends THREE.Mesh {\n" +
              "  constructor(geometry, materials) {\n" +
              "    super(geometry, materials);\n" +
              "\n" +
              "  }\n" +
              "  update(camera) {\n" +
              "    super.update();\n" +
              "  }\n" +
              "  static defaultMatrix() {\n" +
              "    return new THREE.Matrix4();\n" +
              "  }\n" +
              "}\n" +
              "\n" +
              "var fibonacci = {\n" +
              "  [Symbol.iterator]: function*() {\n" +
              "    var pre = 0, cur = 1;\n" +
              "    for (;;) {\n" +
              "      var temp = pre;\n" +
              "      pre = cur;\n" +
              "      cur += temp;\n" +
              "      yield cur;\n" +
              "    }\n" +
              "  }\n" +
              "}\n"
            ],
            "names"    => [],
            "x_sprockets_linecount"=>66
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
    assert_equal [], normalize_uris(asset.links)

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
            "mappings" => "AAAA,AACE,GADC,CACD,EAAE,CAAC;EACD,MAAM,EAAE,CAAC;EACT,OAAO,EAAE,CAAC;EACV,UAAU,EAAE,IAAI,GACjB;;AALH,AAOE,GAPC,CAOD,EAAE,CAAC;EAAE,OAAO,EAAE,YAAY,GAAI;;AAPhC,AASE,GATC,CASD,CAAC,CAAC;EACA,OAAO,EAAE,KAAK;EACd,OAAO,EAAE,QAAQ;EACjB,eAAe,EAAE,IAAI,GACtB",
            "sources"  => ['main.scss'],
            "sourcesContent"=>[
              "nav {\n" +
              "  ul {\n" +
              "    margin: 0;\n" +
              "    padding: 0;\n" +
              "    list-style: none;\n" +
              "  }\n" +
              "\n" +
              "  li { display: inline-block; }\n" +
              "\n" +
              "  a {\n" +
              "    display: block;\n" +
              "    padding: 6px 12px;\n" +
              "    text-decoration: none;\n" +
              "  }\n" +
              "}\n"
            ],
            "names"    => [],
            "x_sprockets_linecount"=>12
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
    assert_equal [], normalize_uris(asset.links)

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
            "mappings" => "ACAA,AAAA,IAAI,CAAC;EAAE,KAAK,EAAE,GAAG,GAAI;;ADErB,AAAA,GAAG,CAAC;EAAE,KAAK,EAAE,IAAI,GAAI",
            "sources"  => [
              "with-import.scss",
              "_imported.scss",
            ],
            "sourcesContent" => [
              "@import 'imported';\n" +
              "\n" +
              "nav { color: blue; }\n",
              "body { color: red; }\n"
            ],
            "names"    => [],
            "x_sprockets_linecount"=>5
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
    assert_equal "foo/index.js-0537e98484a750b47c100f542e6992f7f2fbc09b355f47f1206a9d3adffb65ce.map", mapUrl

    map = JSON.parse(@env.find_asset('foo/index.js.map').source)
    assert_equal [
      "file.coffee",
      "index.js"
    ], get_sources(map)
    assert_equal [
      "console.log(\"foo/file.coffee\") if 1 < 2\n",
      "//= require ./file\n" +
      "console.log(\"foo.js\");\n"
    ], get_sourcesContent(map)
  end

  test "relative sources at different depths" do
    assert @env.find_asset("sub/directory.js", pipeline: :debug)
    assert map = JSON.parse(@env.find_asset("sub/directory.js.map").source)
    assert_equal [
      "a.js",
      "modules/something.js",
      "directory.js"
    ], get_sources(map)
    assert_equal [
      "function a() {\n" +
      "  console.log('sub/a.js')  \n" +
      "}\n",
      "console.log(\"something.js\")\n",
      "//= require ./a\n" +
      "//= require ./modules/something\n" +
      "console.log('sub/directory.js');\n" +
      "a();\n"
    ], get_sourcesContent(map)
  end

  test "source maps are updated correctly after file change" do
    filename = fixture_path('source-maps/sub/a.js')
    sandbox filename do
      expected = JSON.parse(@env.find_asset('sub/directory.js.map').source).tap do |map|
        index = map["sections"].find_index { |s| s["map"]["file"].end_with?('sub/a.js') }
        map["sections"][index]["map"]["mappings"] << ";AACA"
        map["sections"][(index+1)..-1].each do |s|
          s["offset"]["line"] += 1
        end
        map["sections"][index]["map"]["sourcesContent"][0] << "console.log('newline');\n"
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
    assert_equal [], normalize_uris(asset.links)

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
            "mappings" => "AAAA,AACE,GADC,CACD,EAAE,CAAC;EACD,MAAM,EAAE,CAAC;EACT,OAAO,EAAE,CAAC;EACV,UAAU,EAAE,IAAI,GACjB;;AALH,AAOE,GAPC,CAOD,EAAE,CAAC;EAAE,OAAO,EAAE,YAAY,GAAI;;AAPhC,AASE,GATC,CASD,CAAC,CAAC;EACA,OAAO,EAAE,KAAK;EACd,OAAO,EAAE,QAAQ;EACjB,eAAe,EAAE,IAAI,GACtB",
            "sources"  => ["main.scss"],
            "sourcesContent"=>[
              "nav {\n" +
              "  ul {\n" +
              "    margin: 0;\n" +
              "    padding: 0;\n" +
              "    list-style: none;\n" +
              "  }\n" +
              "\n" +
              "  li { display: inline-block; }\n" +
              "\n" +
              "  a {\n" +
              "    display: block;\n" +
              "    padding: 6px 12px;\n" +
              "    text-decoration: none;\n" +
              "  }\n" +
              "}\n"
            ],
            "names"    => [],
            "x_sprockets_linecount"=>12
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
    assert_equal [], normalize_uris(asset.links)

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
            "mappings" => "ACAA,AAAA,IAAI,CAAC;EAAE,KAAK,EAAE,GAAG,GAAI;;ADErB,AAAA,GAAG,CAAC;EAAE,KAAK,EAAE,IAAI,GAAI",
            "sources"  => [
              "with-import.scss",
              "_imported.scss"
            ],
            "sourcesContent" => [
              "@import 'imported';\n" +
              "\n" +
              "nav { color: blue; }\n",
              "body { color: red; }\n"
            ],
            "names"    => [],
            "x_sprockets_linecount"=>5
          }
        }
      ]
    }, map)
  end
end unless RUBY_PLATFORM.include?('java')
