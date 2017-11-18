# frozen_string_literal: true
require 'sprockets_test'
require 'yaml'

class TestContext < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
    @env.append_path(fixture_path('context'))
  end

  test "context environment is cached" do
    instances = @env["environment.js"].to_s.split("\n")
    assert_match "Sprockets::CachedEnvironment", instances[0]
    assert_equal instances[0], instances[1]
  end

  test "source file properties are exposed in context" do
    json = @env["properties.js"].to_s.chomp.chop
    assert_equal({
      'filename'     => fixture_path("context/properties.js.erb"),
      '__FILE__'     => fixture_path("context/properties.js.erb"),
      'root_path'    => fixture_path("context"),
      'logical_path' => "properties",
      'content_type' => "application/javascript"
    }, YAML.load(json))
  end

  test "source file properties are exposed in context when path contains periods" do
    json = @env["properties.with.periods.js"].to_s.chomp.chop
    assert_equal({
      'filename'     => fixture_path("context/properties.with.periods.js.erb"),
      '__FILE__'     => fixture_path("context/properties.with.periods.js.erb"),
      'root_path'    => fixture_path("context"),
      'logical_path' => "properties.with.periods",
      'content_type' => "application/javascript"
    }, YAML.load(json))
  end

  test "asset_data_uri encodes svg using optimized URI-escaping" do
    assert_equal(<<-CSS, @env["svg-embed.css"].to_s)
.svg-embed {
  background: url("data:image/svg+xml;charset=utf-8,%3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='512' height='512' viewBox='0 0 512 512'%3E%3Cpath d='M224 387.814v124.186l-192-192 192-192v126.912c223.375 5.24 213.794-151.896 156.931-254.912 140.355 151.707 110.55 394.785-156.931 387.814z'%3E%3C/path%3E%3C/svg%3E");
}
    CSS
  end

  test "extend context" do
    @env.context_class.class_eval do
      def datauri(path)
        require 'base64'
        Base64.encode64(File.open(path, "rb") { |f| f.read })
      end
    end

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
      @env["helpers.css"].to_s.lines.to_a[0..1].join
    assert_equal 58240, @env["helpers.css"].length
  end

  test "resolve with content type" do
    assert_equal(<<-FILE, @env["resolve_content_type.js"].to_s)
file://#{fixture_path_for_uri("context/foo.js")}?type=application/javascript;
file://#{fixture_path_for_uri("context/foo.js")}?type=application/javascript;
FILE
  end
end

class TestCustomProcessor < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.append_path(fixture_path('context'))
  end

  require 'yaml'
  YamlBundleProcessor = proc do |input|
    env = input[:environment]
    manifest = YAML.load(input[:data])
    paths = manifest['require'].map do |logical_path|
      uri, _ = env.resolve(logical_path)
      uri
    end
    { data: "", required: paths }
  end

  test "custom processor using Context#require" do
    @env.register_mime_type 'text/yaml+bundle', extensions: ['.bundle.yml']
    @env.register_transformer 'text/yaml+bundle', 'application/javascript', YamlBundleProcessor

    assert_equal "var Foo = {};\n\nvar Bar = {};\n", @env['application.js'].to_s
  end

  require 'base64'
  DataUriProcessor = proc do |input|
    env = input[:environment]
    data = input[:data]
    data.gsub(/url\(\"(.+?)\"\)/) do
      uri, _ = env.resolve($1)
      path, _ = env.parse_asset_uri(uri)
      data = Base64.encode64(File.open(path, "rb") { |f| f.read })
      "url(data:image/png;base64,#{data})"
    end
  end

  test "custom processor using Context#resolve and Context#depend_on" do
    @env.register_mime_type 'text/css+embed', extensions: ['.css.embed']
    @env.register_transformer 'text/css+embed', 'text/css', DataUriProcessor

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
      @env["sprite.css"].to_s.lines.to_a[0..1].join
    assert_equal 58240, @env["sprite.css"].length
  end

  test "block custom processor" do
    require 'base64'

    @env.register_preprocessor 'text/css' do |input|
      env = input[:environment]
      input[:data].gsub(/url\(\"(.+?)\"\)/) do
        uri, _ = env.resolve($1)
        path, _ = env.parse_asset_uri(uri)
        data = Base64.encode64(File.open(path, "rb") { |f| f.read })
        "url(data:image/png;base64,#{data})"
      end
    end

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
      @env["sprite2.css"].to_s.lines.to_a[0..1].join
    assert_equal 58240, @env["sprite2.css"].length
  end
end
