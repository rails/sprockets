# frozen_string_literal: true
module SharedSassTestNoFunction
  extend Sprockets::TestDefinition

  test "aren't included globally" do
    silence_warnings do
      assert sass_functions.instance_methods.include?(:javascript_path)
      assert sass_functions.instance_methods.include?(:stylesheet_path)

      filename = fixture_path('sass/paths.scss')
      assert data = File.read(filename)
      engine = sass_engine.new(data, {
        filename: filename,
        syntax: :scss
      })

      assert sass_functions.instance_methods.include?(:javascript_path)
      assert sass_functions.instance_methods.include?(:stylesheet_path)

      assert_equal <<-EOS, engine.render
div {
  url: url(asset-path("foo.svg"));
  url: url(image-path("foo.png"));
  url: url(video-path("foo.mov"));
  url: url(audio-path("foo.mp3"));
  url: url(font-path("foo.woff2"));
  url: url(font-path("foo.woff"));
  url: url("/js/foo.js");
  url: url("/css/foo.css"); }
      EOS
    end
  end
end

module SharedSassTestSprockets
  extend Sprockets::TestDefinition

  test "process variables" do
    assert_equal <<-EOS, render('sass/variables.sass')
.content-navigation {
  border-color: #3bbfce;
  color: #2ca2af; }

.border {
  padding: 8px;
  margin: 8px;
  border-color: #3bbfce; }
    EOS
  end

  test "process nesting" do
    assert_equal <<-EOS, render('sass/nesting.scss')
table.hl {
  margin: 2em 0; }
  table.hl td.ln {
    text-align: right; }

li {
  font-family: serif;
  font-weight: bold;
  font-size: 1.2em; }
    EOS
  end

  test "@import scss partial from scss" do
    assert_equal <<-EOS, render('sass/import_partial.scss')
#navbar li {
  border-top-radius: 10px;
  -moz-border-radius-top: 10px;
  -webkit-border-top-radius: 10px; }

#footer {
  border-top-radius: 5px;
  -moz-border-radius-top: 5px;
  -webkit-border-top-radius: 5px; }

#sidebar {
  border-left-radius: 8px;
  -moz-border-radius-left: 8px;
  -webkit-border-left-radius: 8px; }
    EOS
  end

  test "@import scss partial from sass" do
    assert_equal <<-EOS, render('sass/import_partial.sass')
#navbar li {
  border-top-radius: 10px;
  -moz-border-radius-top: 10px;
  -webkit-border-top-radius: 10px; }

#footer {
  border-top-radius: 5px;
  -moz-border-radius-top: 5px;
  -webkit-border-top-radius: 5px; }

#sidebar {
  border-left-radius: 8px;
  -moz-border-radius-left: 8px;
  -webkit-border-left-radius: 8px; }
    EOS
  end

  test "@import sass non-partial from scss" do
    assert_equal <<-EOS, render('sass/import_nonpartial.scss')
.content-navigation {
  border-color: #3bbfce;
  color: #2ca2af; }

.border {
  padding: 8px;
  margin: 8px;
  border-color: #3bbfce; }
    EOS
  end

  test "@import css file from load path" do
    assert_match /\A\s*\z/, render('sass/import_load_path.scss')
  end

  test "process css file" do
    assert_equal <<-EOS, render('sass/reset.css')
article, aside, details, figcaption, figure,
footer, header, hgroup, menu, nav, section {
  display: block; }
    EOS
  end

  test "@import relative file" do
    assert_equal <<-EOS, render('sass/shared/relative.scss')
#navbar li {
  border-top-radius: 10px;
  -moz-border-radius-top: 10px;
  -webkit-border-top-radius: 10px; }

#footer {
  border-top-radius: 5px;
  -moz-border-radius-top: 5px;
  -webkit-border-top-radius: 5px; }

#sidebar {
  border-left-radius: 8px;
  -moz-border-radius-left: 8px;
  -webkit-border-left-radius: 8px; }
    EOS
  end

  test "@import relative nested file" do
    assert_equal <<-EOS, render('sass/relative.scss')
body {
  background: #666666; }
    EOS
  end

  test "modify file causes it to recompile" do
    filename = fixture_path('sass/test.scss')

    sandbox filename do
      File.open(filename, 'w') { |f| f.write "body { background: red; };" }
      assert_equal "body {\n  background: red; }\n", render(filename)

      File.open(filename, 'w') { |f| f.write "body { background: blue; };" }
      mtime = Time.now + 1
      File.utime(mtime, mtime, filename)

      assert_equal "body {\n  background: blue; }\n", render(filename)
    end
  end

  test "modify partial causes it to recompile" do
    filename, partial = fixture_path('sass/test.scss'), fixture_path('sass/_partial.scss')

    sandbox filename, partial do
      File.open(filename, 'w') { |f| f.write "@import 'partial';" }
      File.open(partial, 'w') { |f| f.write "body { background: red; };" }
      assert_equal "body {\n  background: red; }\n", render(filename)

      File.open(partial, 'w') { |f| f.write "body { background: blue; };" }
      mtime = Time.now + 1
      File.utime(mtime, mtime, partial)

      assert_equal "body {\n  background: blue; }\n", render(filename)
    end
  end

  test "reference @import'd variable" do
    assert_equal <<-EOS, render('sass/links.scss')
a:link {
  color: "red"; }
    EOS
  end

  test "@import reference variable" do
    assert_equal <<-EOS, render('sass/main.scss')
#header {
  color: "blue"; }
    EOS
  end
end

module SharedSassTestCompressor
  extend Sprockets::TestDefinition

  test "compress css" do
    silence_warnings do
      uncompressed = "p {\n  margin: 0;\n  padding: 0;\n}\n"
      compressed   = "p{margin:0;padding:0}\n"
      input = {
        data: uncompressed,
        metadata: {},
        cache: Sprockets::Cache.new
      }
      assert_equal compressed, compressor.call(input)[:data]
    end
  end
end

module SharedSassTestFunctions
  extend Sprockets::TestDefinition

  test "path functions" do
    assert_equal <<-EOS, render('sass/paths.scss')
div {
  url: url("/foo.svg");
  url: url("/foo.png");
  url: url("/foo.mov");
  url: url("/foo.mp3");
  url: url("/foo.woff2");
  url: url("/foo.woff");
  url: url("/foo.js");
  url: url("/foo.css"); }
    EOS
  end

  test "url functions" do
    assert_equal <<-EOS, render('sass/urls.scss')
div {
  url: url(/foo.svg);
  url: url(/foo.png);
  url: url(/foo.mov);
  url: url(/foo.mp3);
  url: url(/foo.woff2);
  url: url(/foo.woff);
  url: url(/foo.js);
  url: url(/foo.css); }
    EOS
  end

  test "url functions with query and hash parameters" do
    assert_equal <<-EOS, render('octicons/octicons.scss')
@font-face {
  font-family: 'octicons';
  src: url(/octicons.eot?#iefix) format("embedded-opentype"), url(/octicons.woff2) format("woff2"), url(/octicons.woff) format("woff"), url(/octicons.ttf) format("truetype"), url(/octicons.svg#octicons) format("svg");
  font-weight: normal;
  font-style: normal; }
    EOS
  end

  test "path function generates links" do
    asset = silence_warnings do
      @env.find_asset('sass/paths.css')
    end
    assert asset

    assert_equal [
      "file://#{fixture_path_for_uri('compass/foo.css')}?type=text/css&id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.js')}?type=application/javascript&id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.mov')}?id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.mp3')}?type=audio/mpeg&id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.svg')}?type=image/png&id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.svg')}?type=image/svg+xml&id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.woff2')}?type=application/font-woff2&id=xxx",
      "file://#{fixture_path_for_uri('compass/foo.woff')}?type=application/font-woff&id=xxx"
    ], asset.links.to_a.map { |uri| uri.sub(/id=\w+/, 'id=xxx') }.sort
  end

  test "data-url function" do
    assert_equal <<-EOS, render('sass/data_url.scss')
div {
  url: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAMAAAAoyzS7AAAABlBMVEUFO2sAAADPfNHpAAAACklEQVQIW2NgAAAAAgABYkBPaAAAAABJRU5ErkJggg%3D%3D); }
    EOS
  end
end
