require 'minitest/autorun'
require 'sprockets/uri_utils'

class TestURIUtils < MiniTest::Test
  include Sprockets::URIUtils

  DOSISH = File::ALT_SEPARATOR != nil
  DOSISH_DRIVE_LETTER = File.dirname("A:") == "A:."
  DOSISH_UNC = File.dirname("//") == "//"

  def test_split_uri
    parts = split_uri("https://josh:Passw0rd1@github.com:433/sstephenson/sprockets/issues?author=josh#issue1")
    assert_equal ["https", "josh:Passw0rd1", "github.com", "433", nil, "/sstephenson/sprockets/issues", nil, "author=josh", "issue1"], parts
  end

  def test_join_uri
    assert_equal "https://josh:Passw0rd1@github.com:433/sstephenson/sprockets/issues?author=josh#issue1",
      join_uri("https", "josh:Passw0rd1", "github.com", "433", nil, "/sstephenson/sprockets/issues", nil, "author=josh", "issue1")
  end

  def test_inverse_uri_functions
    [
      "http://github.com",
      "http://github.com:8080",
      "https://github.com/",
      "https://github.com/home",
      "https://github.com#logo",
      "https://josh:Passw0rd1@github.com:433/sstephenson/sprockets/issues?author=josh#issue1",
      "urn:md5:68b329da9893e34099c7d8ad5cb9c940",
    ].each do |uri|
      assert parts = split_uri(uri)
      assert_equal uri, join_uri(*parts)
    end
  end

  def test_split_file_uri
    parts = split_file_uri("file://localhost/etc/fstab")
    assert_equal ['file', 'localhost', '/etc/fstab', nil], parts

    parts = split_file_uri("file:///etc/fstab")
    assert_equal ['file', nil, '/etc/fstab', nil], parts

    parts = split_file_uri("file:///usr/local/bin/ruby%20on%20rails")
    assert_equal ['file', nil, '/usr/local/bin/ruby on rails', nil], parts

    parts = split_file_uri("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal ['file', nil, '/usr/local/var/github/app/assets/javascripts/application.js', nil], parts

    parts = split_file_uri("file:///C:/Documents%20and%20Settings/davris/FileSchemeURIs.doc")
    assert_equal ['file', nil, 'C:/Documents and Settings/davris/FileSchemeURIs.doc', nil], parts

    parts = split_file_uri("file:///D:/Program%20Files/Viewer/startup.htm")
    assert_equal ['file', nil, 'D:/Program Files/Viewer/startup.htm', nil], parts

    parts = split_file_uri("file:///C:/Program%20Files/Music/Web%20Sys/main.html?REQUEST=RADIO")
    assert_equal ['file', nil, 'C:/Program Files/Music/Web Sys/main.html', 'REQUEST=RADIO'], parts
  end

  def test_join_uri_path
    assert_equal "file://localhost/etc/fstab",
      join_file_uri('file', 'localhost', '/etc/fstab', nil)

    assert_equal "file:///etc/fstab",
      join_file_uri('file', nil, '/etc/fstab', nil)

    assert_equal "file:///usr/local/bin/ruby%20on%20rails",
      join_file_uri('file', nil, '/usr/local/bin/ruby on rails', nil)
  end

  def test_inverse_file_uri_functions
    [
      "file://localhost/etc/fstab",
      "file:///etc/fstab",
      "file:///usr/local/bin/ruby%20on%20rails",
      "file:///usr/local/var/github/app/assets/javascripts/application.js",
      "file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript",
      "file:///C:/Documents%20and%20Settings/davris/FileSchemeURIs.doc",
      "file:///D:/Program%20Files/Viewer/startup.htm"
    ].each do |uri|
      assert parts = split_file_uri(uri)
      assert_equal uri, join_file_uri(*parts)
    end
  end

  def test_validate
    assert valid_asset_uri?("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert valid_asset_uri?("file:///C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
    refute valid_asset_uri?("http:///usr/local/var/github/app/assets/javascripts/application.js")
    refute valid_asset_uri?("/usr/local/var/github/app/assets/javascripts/application.js")
  end

  def test_validate_with_invalid_uri_error
    refute valid_asset_uri?("file:///[]")
  end

  def test_parse_file_paths
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal ["/usr/local/var/github/app/assets/javascripts/foo bar.js", {}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/foo%20bar.js")
    assert_equal ["C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js", {}],
      parse_asset_uri("file:///C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_parse_query_params
    assert_equal ["/usr/local/var/github/app/assets/javascripts/application.coffee", {type: 'application/javascript'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/javascripts/application.coffee?type=application/javascript")
    assert_equal ["/usr/local/var/github/app/assets/stylesheets/users.css", {type: 'text/css', flag: true}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/stylesheets/users.css?type=text/css&flag")
    assert_equal ["/usr/local/var/github/app/assets/views/users.html", {type: 'text/html; charset=utf-8'}],
      parse_asset_uri("file:///usr/local/var/github/app/assets/views/users.html?type=text/html;%20charset=utf-8")
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
    assert_equal "file:///C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
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
    assert_equal "file:///usr/local/var/github/app/assets/stylesheets/users.css?type=css",
      build_asset_uri("/usr/local/var/github/app/assets/stylesheets/users.css", type: :css)
    assert_equal "file:///usr/local/var/github/app/assets/views/users.html?type=text/html;%20charset=utf-8",
      build_asset_uri("/usr/local/var/github/app/assets/views/users.html", type: 'text/html; charset=utf-8')
  end

  def test_raise_error_when_invalid_param_value
    assert_raises TypeError do
      build_asset_uri("/usr/local/var/github/app/assets/images/logo.png", encodings: ['gzip', 'deflate'])
    end
  end

  def test_parse_file_digest_uri
    assert_equal "/usr/local/var/github/app/assets/javascripts/application.js",
      parse_file_digest_uri("file-digest:///usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "/usr/local/var/github/app/assets/javascripts/foo bar.js",
      parse_file_digest_uri("file-digest:///usr/local/var/github/app/assets/javascripts/foo%20bar.js")
    assert_equal "C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
      parse_file_digest_uri("file-digest:///C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_build_file_digest_uri
    assert_equal "file-digest:///usr/local/var/github/app/assets/javascripts/application.js",
      build_file_digest_uri("/usr/local/var/github/app/assets/javascripts/application.js")
    assert_equal "file-digest:///usr/local/var/github/app/assets/javascripts/foo%20bar.js",
      build_file_digest_uri("/usr/local/var/github/app/assets/javascripts/foo bar.js")
    assert_equal "file-digest:///C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js",
      build_file_digest_uri("C:/Users/IEUser/Documents/github/app/assets/javascripts/application.js")
  end

  def test_file_digest_raise_erorr_when_invalid_uri_scheme
    assert_raises URI::InvalidURIError do
      parse_file_digest_uri("http:///usr/local/var/github/app/assets/javascripts/application.js")
    end
  end
end
