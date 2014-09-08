require 'sprockets_test'
require 'sprockets/http_utils'

class TestHTTPUtils < Sprockets::TestCase
  include Sprockets::HTTPUtils

  test "match mime type" do
    assert match_mime_type?("text/html", "text/*")
    assert match_mime_type?("text/plain", "*")
    refute match_mime_type?("text/html", "application/json")
  end

  test "parse q values" do
    assert_equal [], parse_q_values(nil)

    assert_equal [["audio/*", 0.2], ["audio/basic", 1.0]],
      parse_q_values("audio/*; q=0.2, audio/basic")
    assert_equal [["text/plain", 0.5], ["text/html", 1.0], ["text/x-dvi", 0.8], ["text/x-c", 1.0]],
      parse_q_values("text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c")
    assert_equal [["text/*", 1.0], ["text/html", 1.0], ["text/html", 1.0], ["*/*", 1.0]],
      parse_q_values("text/*, text/html, text/html;level=1, */*")
    assert_equal [["text/*", 0.3], ["text/html", 0.7], ["text/html", 1.0], ["text/html", 1.0], ["*/*", 0.5]],
      parse_q_values("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5")

    assert_equal [["iso-8859-5", 1.0], ["unicode-1-1", 0.8]],
      parse_q_values("iso-8859-5, unicode-1-1;q=0.8")

    assert_equal [["compress", 1.0], ["gzip", 1.0]],
      parse_q_values("compress, gzip")
    assert_equal [["*", 1.0]],
      parse_q_values("*")
    assert_equal [["compress", 0.5], ["gzip", 1.0]],
      parse_q_values("compress;q=0.5, gzip;q=1.0")
    assert_equal [["gzip", 1.0], ["identity", 0.5], ["*", 0.0]],
      parse_q_values("gzip;q=1.0, identity; q=0.5, *;q=0")
  end

  test "find q matches" do
    accept = "text/plain; q=0.5, image/*"
    assert_equal ["text/plain"], find_mime_type_matches(accept, ["text/plain"])
    assert_equal ["image/svg+xml"], find_mime_type_matches(accept, ["image/svg+xml"])
    assert_equal ["image/svg+xml"], find_mime_type_matches(accept, ["image/svg+xml", "image/png"])
    assert_equal ["image/svg+xml", "text/plain"], find_mime_type_matches(accept, ["image/svg+xml", "text/plain"])
    assert_equal [], find_mime_type_matches(accept, ["text/css"])
  end

  test "find best q match" do
    accept = "text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c"
    assert_equal "text/plain", find_best_mime_type_match(accept, ["text/plain"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/html"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/plain", "text/html"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/html", "text/plain"])
    refute find_best_mime_type_match(accept, ["text/yaml"])
    refute find_best_mime_type_match(accept, [])

    accept = "sdch, gzip, deflate"
    assert_equal "sdch", find_best_q_match(accept, ["sdch", "gzip"])
    assert_equal "gzip", find_best_q_match(accept, ["gzip"])
    assert_equal "deflate", find_best_q_match(accept, ["deflate"])
    refute find_best_q_match(accept, ["base64"])
    refute find_best_q_match(accept, [])

    refute find_best_q_match(nil, ["gzip"])
  end

  test "find best q match with parsed q values" do
    assert accept = parse_q_values("text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c")
    assert_equal "text/plain", find_best_mime_type_match(accept, ["text/plain"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/html"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/plain", "text/html"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/html", "text/plain"])
  end

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
  end
end
