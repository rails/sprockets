require 'sprockets_test'
require 'sprockets/engines'

class AlertTemplate
  def self.default_mime_type
    'application/javascript'
  end

  def initialize(file, &block)
    @data = block.call
  end

  def render(context)
    "alert(#{@data.inspect});"
  end
end

class StringTemplate
  def initialize(file, &block)
    @data = block.call
  end

  def render(context)
    @data.gsub(/#\{.*?\}/, "moo")
  end
end

class TestEngines < Sprockets::TestCase
  test "registering a global engine" do
    env = new_environment
    env.register_engine ".alert", AlertTemplate
    asset = env["hello.alert"]
    assert_equal 'alert("Hello world!\n");', asset.to_s
    assert_equal 'application/javascript', asset.content_type
  end

  def new_environment
    Sprockets::Environment.new.tap do |env|
      env.append_path(fixture_path('engines'))
    end
  end
end
