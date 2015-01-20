require 'minitest/autorun'
require 'sprockets/uri_utils'

class TestURIUtils < MiniTest::Test
  include Sprockets::URIUtils

  def test_validate
    assert valid_asset_uri?("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert valid_asset_uri?("file://C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
    refute valid_asset_uri?("http:///usr/local/var/github/app/assets/javascripts/application.js")
    refute valid_asset_uri?("/usr/local/var/github/app/assets/javascripts/application.js")
  end

  def test_parse_file_paths
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal ["/usr/local/var/github/app/assets/javascripts/foo bar.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js")
    assert_equal ["C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file://C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_parse_query_params
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.coffee", {type: 'application/javascript'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript")
    assert_equal ["/usr/local/var/github/app/assets/images/logo.png", {encoding: 'gzip'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/images/logo.png?encoding=gzip")
    assert_equal ["/usr/local/var/github/app/assets/stylesheets/users.css", {type: 'text/css', flag: true}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css&flag")
  end

  def test_asset_uri_raise_erorr_when_invalid_uri_scheme
    assert_raises URI::InvalidURIError do
      parse_asset_uri("http:///usr/local/var/github/app/assets/javascripts/application.js")
    end
  end

  def test_build_file_path
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/application.js",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/foo bar.js")
    assert_equal "file://C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
      build_asset_uri("C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_build_query_params
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/application.coffee", type: 'application/javascript')
    assert_equal "file:///usr/local/var/github/app/assets/images/logo.svg?type=image/svg+xml",
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.svg", type: 'image/svg+xml')
    assert_equal "file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css&flag",
      build_asset_uri("/usr/local/var/github/app/assets/stylesheets/users.css", type: 'text/css', flag: true)
    assert_equal "file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css",
      build_asset_uri("/usr/local/var/github/app/assets/stylesheets/users.css", type: 'text/css', flag: false)
    assert_equal "file:///usr/local/var/github/app/assets/images/logo.png?encoding=gzip",
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.png", encoding: 'gzip')
    assert_equal "file:///usr/local/var/github/app/assets/images/logo.png",
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.png", encoding: nil)
  end

  def test_raise_error_when_invalid_param_value
    assert_raises TypeError do
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.png", encodings: ['gzip', 'deflate'])
    end
  end

  def test_parse_file_digest_uri
    assert_equal "/usr/local/var/github/app/assets/javascripts/application.js",
      parse_file_digest_uri("file-digest:/usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "/usr/local/var/github/app/assets/javascripts/foo bar.js",
      parse_file_digest_uri("file-digest:/usr/local/var/github/app/assets/javascripts/foo%20bar.js")
    assert_equal "C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
      parse_file_digest_uri("file-digest:C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_build_file_digest_uri
    assert_equal "file-digest:/usr/local/var/github/app/assets/javascripts/application.js",
      build_file_digest_uri("/usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "file-digest:/usr/local/var/github/app/assets/javascripts/foo%20bar.js",
      build_file_digest_uri("/usr/local/var/github/app/assets/javascripts/foo bar.js")
    assert_equal "file-digest:C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
      build_file_digest_uri("C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_file_digest_raise_erorr_when_invalid_uri_scheme
    assert_raises URI::InvalidURIError do
      parse_file_digest_uri("http:/usr/local/var/github/app/assets/javascripts/application.js")
    end
  end

  def test_build_processor_uri
    assert_equal "processor:bundle",
      build_processor_uri(:bundle)
    assert_equal "processor:preprocessor?type=application/javascript&position=1&class_name=Proc",
      build_processor_uri(:preprocessor, proc {}, type: 'application/javascript', position: 1)
    assert_equal "processor:preprocessor?type=text/css&name=String",
      build_processor_uri(:preprocessor, String, type: 'text/css')
  end
end
