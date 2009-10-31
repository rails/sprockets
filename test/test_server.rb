require "test_helper"

class TestServer < Test::Unit::TestCase
  def setup
    @server = Sprockets::Server.new(:root => FIXTURES_PATH,
      :source_files => ["src/foo.js"])
  end

  def test_source
    assert_equal content_of_fixture("src/foo.js"), @server.source
  end

  def test_md5
    assert_equal "9f46f6250fec57f2714b47ea0cd33268", @server.md5
  end

  def test_last_modified
    assert_kind_of(Time, @server.last_modified)
  end

  def test_etag
    assert_equal "\"9f46f6250fec57f2714b47ea0cd33268\"", @server.etag
  end

  def test_serves_source_with_cache_headers
    status, headers, body = @server.call({})

    assert_equal 200, status
    assert_equal "text/javascript", headers["Content-Type"]
    assert_equal "15", headers["Content-Length"]
    assert_equal content_of_fixture("src/foo.js"), body.join

    assert_equal "\"9f46f6250fec57f2714b47ea0cd33268\"", headers["ETag"]
    assert_equal @server.last_modified.httpdate, headers["Last-Modified"]
    assert_equal "public, must-revalidate", headers["Cache-Control"]
  end

  def test_serves_no_body_if_head_request
    status, headers, body = @server.call({"REQUEST_METHOD" => "HEAD"})

    assert_equal 200, status
    assert_equal "text/javascript", headers["Content-Type"]
    assert_equal "15", headers["Content-Length"]
    assert_equal "", body.join

    assert_equal "\"9f46f6250fec57f2714b47ea0cd33268\"", headers["ETag"]
    assert_equal @server.last_modified.httpdate, headers["Last-Modified"]
    assert_equal "public, must-revalidate", headers["Cache-Control"]
  end

  def test_serves_long_expiry_if_query_string_is_md5
    status, headers, body = @server.call({"QUERY_STRING" => "9f46f6250fec57f2714b47ea0cd33268"})
    assert_equal "public, must-revalidate, max-age=31540000", headers["Cache-Control"]
  end

  def test_serves_not_modified_is_etag_is_valid
    status, headers, body = @server.call({"HTTP_IF_NONE_MATCH" => "\"9f46f6250fec57f2714b47ea0cd33268\""})

    assert_equal 304, status
    assert_equal "", body.join
  end

  def test_serves_not_modified_is_last_modified_is_valid
    status, headers, body = @server.call({"HTTP_IF_MODIFIED_SINCE" => @server.last_modified.httpdate})

    assert_equal 304, status
    assert_equal "", body.join
  end

  def test_serves_source_if_etag_is_stale
    status, headers, body = @server.call({"HTTP_IF_NONE_MATCH" => "\"123\""})

    assert_equal 200, status
    assert_equal content_of_fixture("src/foo.js"), body.join
  end
end
