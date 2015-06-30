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
      "file://#{fixture_path('source-maps/coffee/main.coffee')}?type=text/coffeescript&pipeline=source&id=xxx"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version" => 3,
      "file" => "coffee/main.js",
      "mappings" => "AADA;AAAA,MAAA,sDAAA;IAAA,gBAAA;;AAAA,EAAA,MAAA,GAAA,EAAA,CAAA;;AAAA,EAAA,QAAA,GAAA,IAAA,CAAA;;AAAA,EAAA,IAAA,QAAA;AAAA,IAAA,MAAA,GAAA,CAAA,EAAA,CAAA;GAAA;;AAAA,EAAA,MAAA,GAAA,SAAA,CAAA,GAAA;WAAA,CAAA,GAAA,EAAA;EAAA,CAAA,CAAA;;AAAA,EAAA,IAAA,GAAA,CAAA,CAAA,EAAA,CAAA,EAAA,CAAA,EAAA,CAAA,EAAA,CAAA,CAAA,CAAA;;AAAA,EAAA,IAAA,GAAA;AAAA,IAAA,IAAA,EAAA,IAAA,CAAA,IAAA;AAAA,IAAA,MAAA,EAAA,MAAA;AAAA,IAAA,IAAA,EAAA,SAAA,CAAA,GAAA;aAAA,CAAA,GAAA,MAAA,CAAA,CAAA,EAAA;IAAA,CAAA;GAAA,CAAA;;AAAA,EAAA,IAAA,GAAA,SAAA,GAAA;AAAA,QAAA,eAAA;AAAA,IAAA,uBAAA,+DAAA,CAAA;WAAA,KAAA,CAAA,MAAA,EAAA,OAAA,EAAA;EAAA,CAAA,CAAA;;AAAA,EAAA,IAAA,8CAAA;AAAA,IAAA,KAAA,CAAA,YAAA,CAAA,CAAA;GAAA;;AAAA,EAAA,KAAA;;AAAA;SAAA,sCAAA;oBAAA;AAAA,mBAAA,IAAA,CAAA,IAAA,CAAA,GAAA,EAAA,CAAA;AAAA;;MAAA,CAAA;AAAA",
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
      "file://#{fixture_path('source-maps/sass/main.scss')}?type=text/scss&pipeline=source&id=xxx"
    ], normalize_uris(asset.links)

    assert map = JSON.parse(asset.source)
    assert_equal({
      "version" => 3,
      "file" => "sass/main.css",
      "mappings" => "AADA,MAAA;EAAA,MAAA,EAAA,CAAA;EAAA,OAAA,EAAA,CAAA;EAAA,UAAA,EAAA,IAAA;AAAA,MAAA;EAAA,OAAA,EAAA,YAAA;AAAA,KAAA;EAAA,OAAA,EAAA,KAAA;EAAA,OAAA,EAAA,QAAA;EAAA,eAAA,EAAA,IAAA",
      "sources" => ["sass/main.source-86fe07ad89fecbab307d376bcadfa23d65ad108e3735b564510246b705f6ced1.scss"],
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
