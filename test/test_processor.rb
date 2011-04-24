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
end
