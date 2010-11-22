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
    @javascripts_app ||= Sprockets::Server.new(@env)
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

  test "serve source with etag headers" do
    get "/javascripts/application.js"
    assert_equal '"3aede9c70a76e611d43a1c5f1fb1708a"',
      last_response.headers['ETag']
  end

  test "updated file updates the last modified header" do
    get "/javascripts/application.js"
    time_before_touching = last_response.headers['Last-Modified']

    get "/javascripts/application.js"
    time_after_touching = last_response.headers['Last-Modified']

    assert_equal time_before_touching, time_after_touching

    touch_fixture "server/app/javascripts/foo.js"

    get "/javascripts/application.js"
    time_after_touching = last_response.headers['Last-Modified']

    assert_not_equal time_before_touching, time_after_touching
  end

  test "not modified response when headers match" do
    get "/javascripts/application.js"
    assert_equal 200, last_response.status

    touch_fixture "server/app/javascripts/bar.js"

    get "/javascripts/bar.js", {},
      'HTTP_IF_MODIFIED_SINCE' =>
        File.mtime(fixture_path("server/app/javascripts/bar.js")).httpdate

    assert_equal 304, last_response.status
    assert_equal nil, last_response.headers['Content-Type']
    assert_equal nil, last_response.headers['Content-Length']
  end

  test "if sources didnt change the server shouldnt rebundle" do
    get "/javascripts/application.js"
    asset_before = @javascripts_app.send(:lookup_asset, "PATH_INFO" => "/application.js")
    assert asset_before

    get "/javascripts/application.js"
    asset_after = @javascripts_app.send(:lookup_asset, "PATH_INFO" => "/application.js")
    assert asset_after

    assert asset_before.equal?(asset_after)
  end

  test "query string md5 sets expiration to the future" do
    get "/javascripts/application.js"
    etag = last_response.headers['ETag']

    get "/javascripts/application.js?#{etag[1..-2]}"
    assert_match %r{max-age}, last_response.headers['Cache-Control']
  end

  test "missing source" do
    get "/javascripts/none.js"
    assert_equal 404, last_response.status
  end

  # TODO
  # test "add new source to glob" do
  #   get "/javascripts/glob.js"
  #   assert_equal "var foo;\nvar bar;\n", last_response.body

  #   File.open(fixture_path("server/app/javascripts/baz.js"), "w") do |f|
  #     f.puts "var baz;"
  #   end

  #   begin
  #     get "/javascripts/glob.js"
  #     assert_equal "var foo;\nvar bar;\nvar baz;\n", last_response.body
  #   ensure
  #     FileUtils.rm(fixture_path("server/app/javascripts/baz.js"))
  #   end
  # end

  private
    def touch_fixture(path)
      system "touch", fixture_path(path)
    end
end
