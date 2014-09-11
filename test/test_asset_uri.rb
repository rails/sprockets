require 'sprockets_test'
require 'sprockets/asset_uri'

class TestAssetURI < Sprockets::TestCase
  include Sprockets::AssetURI

  test "build asset uri" do
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/application.js",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/foo bar.js")
    assert_equal "file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript",
      build_asset_uri("/usr/local/var/github/app/assets/javascripts/application.coffee", type: 'application/javascript')
    assert_equal "file:///usr/local/var/github/app/assets/images/logo.svg?type=image/svg+xml",
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.svg", type: 'image/svg+xml')
    assert_equal "file:///usr/local/var/github/app/assets/images/logo.svg?type=image/svg+xml&etag=da39a3ee5e6b4b0d3255bfef95601890afd80709",
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.svg", type: 'image/svg+xml', etag: 'da39a3ee5e6b4b0d3255bfef95601890afd80709')
    assert_equal "file:///usr/local/var/github/app/assets/dump.bin?etag=da39a3ee5e6b4b0d3255bfef95601890afd80709",
      build_asset_uri("/usr/local/var/github/app/assets/dump.bin", etag: "da39a3ee5e6b4b0d3255bfef95601890afd80709")
    assert_equal "file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css&processed",
      build_asset_uri("/usr/local/var/github/app/assets/stylesheets/users.css", type: 'text/css', processed: true)
  end

  test "parse asset uri" do
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal ["/usr/local/var/github/app/assets/javascripts/foo bar.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js")
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.coffee", {type: 'application/javascript'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript")
    assert_equal ["/usr/local/var/github/app/assets/images/logo.svg", {type: 'image/svg+xml', etag: 'da39a3ee5e6b4b0d3255bfef95601890afd80709'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/images/logo.svg?type=image/svg+xml&etag=da39a3ee5e6b4b0d3255bfef95601890afd80709")
    assert_equal ["/usr/local/var/github/app/assets/stylesheets/users.css", {type: 'text/css', processed: true}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css&processed")

    assert_raises Sprockets::InvalidURIError do
      parse_asset_uri("http:///usr/local/var/github/app/assets/javascripts/application.js")
    end
  end
end
