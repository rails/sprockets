require "sprockets_test"

require 'rack/builder'
require 'rack/test'

class TestServer < Sprockets::TestCase
  include Rack::Test::Methods

  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path("server/app/javascripts")
  end

  def javascripts_app
    Sprockets::Server.new(@env)
  end

  def default_app
    javascripts_app = self.javascripts_app

    Rack::Builder.new do
      map "/javascripts" do
        run javascripts_app
      end
    end
  end

  def app
    @app ||= default_app
  end

  test "serve single source file" do
    get "/javascripts/foo.js"
    assert_equal "var foo;\n", last_response.body
  end

  test "serve source with dependencies" do
    get "/javascripts/application.js"
    assert_equal "var foo;\n\n(function() {\n  application.boot();\n})();\n",
      last_response.body
  end

  test "serve source with content type headers" do
    get "/javascripts/application.js"
    assert_equal "application/javascript", last_response.headers['Content-Type']
  end
end
