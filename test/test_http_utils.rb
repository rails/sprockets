require 'minitest/autorun'
require 'sprockets/http_utils'

class TestHTTPUtils < MiniTest::Test
  include Sprockets::HTTPUtils

  def test_match_mime_type
    assert match_mime_type?("text/html", "text/*")
    assert match_mime_type?("text/plain", "*")
    refute match_mime_type?("text/html", "application/json")
  end

  def test_match_mime_type_keys
    h = {
      "text/html" => 1,
      "text/plain" => 2,
      "application/json" => 3,
      "text/*" => 4,
      "*/*" => 5,
      "*" => 6
    }

    assert_equal [6, 5, 4, 1], match_mime_type_keys(h, "text/html")
    assert_equal [6, 5, 4, 2], match_mime_type_keys(h, "text/plain")
    assert_equal [6, 5, 3], match_mime_type_keys(h, "application/json")
    assert_equal [6, 5], match_mime_type_keys(h, "application/javascript")
  end

  def test_parse_q_values
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

  def test_find_q_matches
    accept = "text/plain; q=0.5, image/*"
    assert_equal ["text/plain"], find_mime_type_matches(accept, ["text/plain"])
    assert_equal ["image/svg+xml"], find_mime_type_matches(accept, ["image/svg+xml"])
    assert_equal ["image/svg+xml"], find_mime_type_matches(accept, ["image/svg+xml", "image/png"])
    assert_equal ["image/svg+xml", "text/plain"], find_mime_type_matches(accept, ["image/svg+xml", "text/plain"])
    assert_equal [], find_mime_type_matches(accept, ["text/css"])
  end

  def test_find_matches_with_parsed_q_values
    accept = [["text/plain", 0.5], ["image/*", 1.0]]
    assert_equal ["text/plain"], find_mime_type_matches(accept, ["text/plain"])
    assert_equal ["image/svg+xml"], find_mime_type_matches(accept, ["image/svg+xml"])
    assert_equal ["image/svg+xml"], find_mime_type_matches(accept, ["image/svg+xml", "image/png"])
    assert_equal ["image/svg+xml", "text/plain"], find_mime_type_matches(accept, ["image/svg+xml", "text/plain"])
    assert_equal [], find_mime_type_matches(accept, ["text/css"])
  end

  def test_find_best_q_match
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

  def test_find_best_q_match_with_parsed_q_values
    assert accept = parse_q_values("text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c")
    assert_equal "text/plain", find_best_mime_type_match(accept, ["text/plain"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/html"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/plain", "text/html"])
    assert_equal "text/html", find_best_mime_type_match(accept, ["text/html", "text/plain"])
  end
end
