require 'sprockets_test'
require 'yaml'

class TestContext < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new('.')
    @env.append_path(fixture_path('context'))
  end

  test 'context environment is cached' do
    instances = @env['environment.js'].to_s.split("\n")
    assert_match 'Sprockets::CachedEnvironment', instances[0]
    assert_equal instances[0], instances[1]
  end

  test 'source file properties are exposed in context' do
    json = @env['properties.js'].to_s.chomp.chop
    assert_equal({
                   'filename'     => fixture_path('context/properties.js.erb'),
                   '__FILE__'     => fixture_path('context/properties.js.erb'),
                   'root_path'    => fixture_path('context'),
                   'logical_path' => 'properties',
                   'content_type' => 'application/javascript'
                 }, YAML.load(json))
  end

  test 'source file properties are exposed in context when path contains periods' do
    json = @env['properties.with.periods.js'].to_s.chomp.chop
    assert_equal({
                   'filename'     => fixture_path('context/properties.with.periods.js.erb'),
                   '__FILE__'     => fixture_path('context/properties.with.periods.js.erb'),
                   'root_path'    => fixture_path('context'),
                   'logical_path' => 'properties.with.periods',
                   'content_type' => 'application/javascript'
                 }, YAML.load(json))
  end

  test 'extend context' do
    @env.context_class.class_eval do
      def datauri(path)
        require 'base64'
        Base64.encode64(File.open(path, 'rb', &:read))
      end
    end

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
                 @env['helpers.css'].to_s.lines.to_a[0..1].join
    assert_equal 58_240, @env['helpers.css'].length
  end

  test 'resolve with content type' do
    assert_equal [
      "file://#{fixture_path_for_uri('context/foo.js')}?type=application/javascript",
      "file://#{fixture_path_for_uri('context/foo.js')}?type=application/javascript"
    ].join(",\n"), @env['resolve_content_type.js'].to_s.strip
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
      uri, = env.resolve(logical_path)
      uri
    end
    { data: '', required: paths }
  end

  test 'custom processor using Context#require' do
    @env.register_mime_type 'text/yaml+bundle', extensions: ['.bundle.yml']
    @env.register_transformer 'text/yaml+bundle', 'application/javascript', YamlBundleProcessor

    assert_equal "var Foo = {};\n\nvar Bar = {};\n", @env['application.js'].to_s
  end

  require 'base64'
  DataUriProcessor = proc do |input|
    env = input[:environment]
    data = input[:data]
    data.gsub(/url\(\"(.+?)\"\)/) do
      uri, = env.resolve(Regexp.last_match(1))
      path, = env.parse_asset_uri(uri)
      data = Base64.encode64(File.open(path, 'rb', &:read))
      "url(data:image/png;base64,#{data})"
    end
  end

  test 'custom processor using Context#resolve and Context#depend_on' do
    @env.register_mime_type 'text/css+embed', extensions: ['.css.embed']
    @env.register_transformer 'text/css+embed', 'text/css', DataUriProcessor

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
                 @env['sprite.css'].to_s.lines.to_a[0..1].join
    assert_equal 58_240, @env['sprite.css'].length
  end

  test 'block custom processor' do
    require 'base64'

    @env.register_preprocessor 'text/css' do |input|
      env = input[:environment]
      input[:data].gsub(/url\(\"(.+?)\"\)/) do
        uri, = env.resolve(Regexp.last_match(1))
        path, = env.parse_asset_uri(uri)
        data = Base64.encode64(File.open(path, 'rb', &:read))
        "url(data:image/png;base64,#{data})"
      end
    end

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
                 @env['sprite2.css'].to_s.lines.to_a[0..1].join
    assert_equal 58_240, @env['sprite2.css'].length
  end
end
