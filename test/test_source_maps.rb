require 'sprockets_test'
require 'sprockets/bundle'

silence_warnings do
  require 'sass'
end

class TestSourceMaps < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.append_path fixture_path('source-maps')
  end

  test "builds a source map for js files" do
    asset = @env['child.js']
    map = asset.metadata[:map]
    assert_equal ['child.source-1fa5b1a0f53ee03f5b38d4c5b2346d338916e58b0656d6c37f84bd4c742e49c1.js'], map.map { |m| m[:source] }.uniq.compact
  end

  test "builds a concatenated source map" do
    asset = @env['application.js']
    map = asset.metadata[:map]
    assert_equal [
      "project.source-8c5bc45531c819bca8f1ff1667663276a6a95b02668d2483933f877bf8385e1c.coffee",
      "users.source-97778acdc614f43b92cf4711aecbc71ce3af98081418a80068a107d87c142a60.coffee",
      "application.source-eb88d0e61cf8b783aa9402689bb0fd8579514480b446c68fe7e17e8d9d09b67a.coffee"
    ], map.map { |m| m[:source] }.uniq.compact
  end

  test "builds a minified source map" do
    @env.js_compressor = :uglifier

    asset = @env['application.js']
    map = asset.metadata[:map]
    assert map.all? { |mapping| mapping[:generated][0] == 1 }
    assert_equal [
      "project.source-8c5bc45531c819bca8f1ff1667663276a6a95b02668d2483933f877bf8385e1c.coffee",
      "users.source-97778acdc614f43b92cf4711aecbc71ce3af98081418a80068a107d87c142a60.coffee",
      "application.source-eb88d0e61cf8b783aa9402689bb0fd8579514480b446c68fe7e17e8d9d09b67a.coffee"
    ], map.map { |m| m[:source] }.uniq.compact
  end

  test "builds a source map with js dependency" do
    asset = @env['parent.js']
    map = asset.metadata[:map]
    assert_equal [
      "child.source-1fa5b1a0f53ee03f5b38d4c5b2346d338916e58b0656d6c37f84bd4c742e49c1.js",
      "users.source-97778acdc614f43b92cf4711aecbc71ce3af98081418a80068a107d87c142a60.coffee",
      "parent.source-4cd7e6dee61e33d04dae677fcd1f593cf7b2abbc12b247dedee6ae87b8e9f713.js"
    ], map.map { |m| m[:source] }.uniq.compact
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
      "version" => 3,
      "file" => "coffee/main.js",
      "mappings" => "AACA;AAAA,MAAA,sDAAA;IAAA;;EAAA,MAAA,GAAW;;EACX,QAAA,GAAW;;EAGX,IAAgB,QAAhB;IAAA,MAAA,GAAS,CAAC,GAAV;;;EAGA,MAAA,GAAS,SAAC,CAAD;WAAO,CAAA,GAAI;EAAX;;EAGT,IAAA,GAAO,CAAC,CAAD,EAAI,CAAJ,EAAO,CAAP,EAAU,CAAV,EAAa,CAAb;;EAGP,IAAA,GACE;IAAA,IAAA,EAAQ,IAAI,CAAC,IAAb;IACA,MAAA,EAAQ,MADR;IAEA,IAAA,EAAQ,SAAC,CAAD;aAAO,CAAA,GAAI,MAAA,CAAO,CAAP;IAAX,CAFR;;;EAKF,IAAA,GAAO,SAAA;AACL,QAAA;IADM,uBAAQ;WACd,KAAA,CAAM,MAAN,EAAc,OAAd;EADK;;EAIP,IAAsB,8CAAtB;IAAA,KAAA,CAAM,YAAN,EAAA;;;EAGA,KAAA;;AAAS;SAAA,sCAAA;;mBAAA,IAAI,CAAC,IAAL,CAAU,GAAV;AAAA;;;AA1BT",
      "sources" => ["coffee/main.source-2ee93f5e7f3b843c3002478375432cf923860432879315335f4b987c205057db.coffee"],
      "names" => []
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
      "version" => 3,
      "file" => "babel/main.js",
      "mappings" => ";;;;;;;;;;AACA,IAAI,IAAI,GAAG,KAAK,CAAC,GAAG,CAAC,UAAA,CAAC;SAAI,CAAC,GAAG,CAAC;CAAA,CAAC,CAAC;AACjC,IAAI,IAAI,GAAG,KAAK,CAAC,GAAG,CAAC,UAAC,CAAC,EAAE,CAAC;SAAK,CAAC,GAAG,CAAC;CAAA,CAAC,CAAC;;IAEhC,WAAW;YAAX,WAAW;;AACJ,WADP,WAAW,CACH,QAAQ,EAAE,SAAS,EAAE;0BAD7B,WAAW;;AAEb,+BAFE,WAAW,6CAEP,QAAQ,EAAE,SAAS,EAAE;GAE5B;;eAJG,WAAW;;WAKT,gBAAC,MAAM,EAAE;AACb,iCANE,WAAW,wCAME;KAChB;;;WACmB,yBAAG;AACrB,aAAO,IAAI,KAAK,CAAC,OAAO,EAAE,CAAC;KAC5B;;;SAVG,WAAW;GAAS,KAAK,CAAC,IAAI;;AAapC,IAAI,SAAS,uBACV,MAAM,CAAC,QAAQ,0BAAG;MACb,GAAG,EAAM,GAAG,EAEV,IAAI;;;;AAFN,WAAG,GAAG,CAAC,EAAE,GAAG,GAAG,CAAC;;;AAEd,YAAI,GAAG,GAAG;;AACd,WAAG,GAAG,GAAG,CAAC;AACV,WAAG,IAAI,IAAI,CAAC;;eACN,GAAG;;;;;;;;;;;CAEZ,EACF,CAAA",
      "sources" => ["babel/main.source-1acb9cf16a3e1ce0fe0a38491472a14a6a97281ceace4b67ec16a904be5fa1b9.es6"],
      "names"=>[]
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
      "version" => 3,
      "file" => "sass/main.css",
      "mappings" => "AACE,MAAG;EACD,MAAM,EAAE,CAAC;EACT,OAAO,EAAE,CAAC;EACV,UAAU,EAAE,IAAI;AAGlB,MAAG;EAAE,OAAO,EAAE,YAAY;AAE1B,KAAE;EACA,OAAO,EAAE,KAAK;EACd,OAAO,EAAE,QAAQ;EACjB,eAAe,EAAE,IAAI",
      "sources" => ["sass/main.source-86fe07ad89fecbab307d376bcadfa23d65ad108e3735b564510246b705f6ced1.scss"],
      "names" => []
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
      "version" => 3,
      "file" => "sass/with-import.css",
      "mappings" => "AAAA,IAAK;EAAE,KAAK,EAAE,GAAG;;ACEjB,GAAI;EAAE,KAAK,EAAE,IAAI",
      "sources" => [
        "sass/_imported.source-9767e91e9d4b0334e59a1d389e9801bc6a2c5c4a5500a3c2c7915687965b2c16.scss",
        "sass/with-import.source-5d53742ba113ac26396986bf14ab5c7e19ef193e494d5d868a9362e3e057cb26.scss"
      ],
      "names" => []
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
      "file://#{fixture_path('source-maps/sass/main.scss')}?type=text/scss&pipeline=source"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version"  => 3,
      "file"     => "sass/main.css",
      "mappings" => "AAAA,AACE,GADC,CACD,EAAE,CAAC;EACD,MAAM,EAAE,CAAE;EACV,OAAO,EAAE,CAAE;EACX,UAAU,EAAE,IAAK,GAClB;;AALH,AAOE,GAPC,CAOD,EAAE,CAAC;EAAE,OAAO,EAAE,YAAa,GAAI;;AAPjC,AASE,GATC,CASD,CAAC,CAAC;EACA,OAAO,EAAE,KAAM;EACf,OAAO,EAAE,QAAS;EAClB,eAAe,EAAE,IAAK,GACvB",
      "sources"  => ["sass/main.source-86fe07ad89fecbab307d376bcadfa23d65ad108e3735b564510246b705f6ced1.scss"],
      "names"    => []
    }, map)
  end
end
