require 'sprockets_test'
require 'tilt'

class TestCustomProcessor < Sprockets::TestCase
  class YamlProcessor < Tilt::Template
    def initialize_engine
      require 'yaml'
    end

    def prepare
      @manifest = YAML.load(data)
    end

    def evaluate(context, locals)
      @manifest['require'].each do |pathname|
        context.concatenation.require(pathname)
      end
      ""
    end
  end

  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path('processor')
  end

  test "custom processor using Concatenation#require" do
    # TODO: Register on @env instance
    Sprockets::Environment.register :yml, YamlProcessor
    @env.engine_extensions << 'yml'

    assert_equal "var Foo = {};\n\nvar Bar = {};\n", @env['application.js'].to_s
  end

  class DataUriProcessor < Tilt::Template
    def initialize_engine
      require 'base64'
    end

    def prepare
    end

    def evaluate(context, locals)
      data.gsub(/url\(\"(.+?)\"\)/) do
        path = context.concatenation.resolve($1)
        context.concatenation.depend(path)
        data = Base64.encode64(File.open(path, "rb") { |f| f.read })
        "url(data:image/png;base64,#{data})"
      end
    end
  end

  test "custom processor using Concatenation#resolve and #depend" do
    # TODO: Register on @env instance
    Sprockets::Environment.register :embed, DataUriProcessor
    @env.engine_extensions << 'embed'

    assert_equal ".pow {\n  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZoAAAEsCAMAAADNS4U5AAAAGXRFWHRTb2Z0\n",
      @env["sprite.css"].to_s.lines.to_a[0..1].join
    assert_equal 58240, @env["sprite.css"].length
  end
end
