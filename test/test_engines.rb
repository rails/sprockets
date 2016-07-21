require 'sprockets_test'
require 'sprockets/engines'

class AlertProcessor
  def self.default_mime_type
    'application/javascript'
  end

  def initialize(file, &block)
    @data = block.call
  end

  def render(context, locals = {})
    "alert(#{@data.inspect});"
  end
end

class StringProcessor
  def initialize(file, &block)
    @data = block.call
  end

  def render(context, locals = {})
    @data.gsub(/#\{.*?\}/, "moo")
  end
end

class TestEngines < Sprockets::TestCase
  test "registering engine" do
    env = new_environment

    Sprockets::SilenceDeprecation.silence do
      env.register_engine ".alert", AlertProcessor, silence_deprecation: true
    end

    asset = env["hello.alert"]
    assert_equal "alert(\"Hello world!\\n\");\n", asset.to_s
    assert_equal 'application/javascript', asset.content_type
  end

  def new_environment
    Sprockets::Environment.new.tap do |env|
      env.append_path(fixture_path('engines'))
    end
  end
end
