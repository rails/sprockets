require 'sprockets_test'

class TestURITar < Sprockets::TestCase
  test "works with windows" do
    fake_env = Class.new do
      include Sprockets::PathUtils
      attr_accessor :root
    end.new

    uri = "C:/Sites/sprockets/test/fixtures/paths/application.css?type=text/css"
    fake_env.root = "C:/Different/path"
    tar = Sprockets::URITar.new(uri, fake_env)
    assert_equal uri, tar.expand
    assert_equal uri, tar.compress
    assert_equal uri, tar.compressed_path

    uri = "file:///C:/Sites/sprockets/test/fixtures/paths/application.css?type=text/css"
    fake_env.root = "C:/Sites/sprockets"
    tar = Sprockets::URITar.new(uri, fake_env)
    assert_equal uri, tar.expand
    assert_equal Sprockets::URITar.new(tar.expand, fake_env).expand, tar.expand
    assert_equal "test/fixtures/paths/application.css?type=text/css", tar.compressed_path
    assert_equal "file://test/fixtures/paths/application.css?type=text/css", tar.compress
    assert_equal Sprockets::URITar.new(tar.compress, fake_env).compress, tar.compress
    assert_equal Sprockets::URITar.new(tar.expand, fake_env).compress, tar.compress

    uri = "C:/Sites/sprockets/test/fixtures/paths/application.css?type=text/css"
    fake_env.root = "C:/Sites/sprockets"
    tar = Sprockets::URITar.new(uri, fake_env)
    assert_equal uri, tar.expand
    assert_equal "test/fixtures/paths/application.css?type=text/css", tar.compressed_path
    assert_equal "test/fixtures/paths/application.css?type=text/css", tar.compress
  end
end
