require 'sprockets_test'
require 'sprockets/uri_utils'

class TestURIUtils < Sprockets::TestCase
  include Sprockets::URIUtils

  test "validate" do
    assert valid_asset_uri?("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert valid_asset_uri?("file://C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
    refute valid_asset_uri?("http:///usr/local/var/github/app/assets/javascripts/application.js")
    refute valid_asset_uri?("/usr/local/var/github/app/assets/javascripts/application.js")
  end

  test "parse file paths" do
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal ["/usr/local/var/github/app/assets/javascripts/foo bar.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js")
    assert_equal ["C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file://C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  test "parse query params" do
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.coffee", {type: 'application/javascript'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript")
    assert_equal ["/usr/local/var/github/app/assets/images/logo.png", {encoding: 'gzip'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/images/logo.png?encoding=gzip")
    assert_equal ["/usr/local/var/github/app/assets/stylesheets/users.css", {type: 'text/css', flag: true}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css&flag")
  end

  test "raise erorr when invalid uri scheme" do
    assert_raises URI::InvalidURIError do
      parse_asset_uri("http:///usr/local/var/github/app/assets/javascripts/application.js")
    end
  end

  test "build file path" do
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/application.js",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/foo bar.js")
    assert_equal "file://C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
      build_asset_uri("C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  test "build query params" do
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

  test "raise error when invalid param value" do
    assert_raises TypeError do
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.png", encodings: ['gzip', 'deflate'])
    end
  end
end
