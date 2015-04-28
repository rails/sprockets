# encoding: utf-8
require 'minitest/autorun'
require 'sprockets/encoding_utils'

class TestDigestUtils < MiniTest::Test
  include Sprockets::EncodingUtils

  def test_deflate
    output = deflate("foobar")
    assert_equal 8, output.length
    assert_equal [75, 203, 207, 79, 74, 44, 2, 0], output.bytes.take(8)
  end

  def test_gzip
    output = gzip("foobar")
    assert_equal 26, output.length
    assert_equal [31, 139, 8, 0, 1, 0, 0, 0], output.bytes.take(8)
  end

  def test_base64
    assert_equal "Zm9vYmFy", base64("foobar")
  end

  def test_unmarshal
    str = Marshal.dump("abc")
    assert_equal Marshal.load(str), unmarshaled_deflated(str)
  end

  def test_unmarshal_older_minor_version
    old_verbose, $VERBOSE = $VERBOSE, false
    begin
      str = Marshal.dump("abc")
      str[1] = "\0"
      assert_equal Marshal.load(str), unmarshaled_deflated(str)
    ensure
      $VERBOSE = old_verbose
    end
  end

  def test_fail_to_unmarshal_older_major_version
    str = Marshal.dump("abc")
    str[0] = "\1"

    assert_raises TypeError do
      Marshal.load(str)
    end

    assert_raises TypeError do
      unmarshaled_deflated(str)
    end
  end

  def test_fail_to_unmarshal_not_enough_data
    assert_raises ArgumentError do
      Marshal.load("")
    end

    assert_raises ArgumentError do
      unmarshaled_deflated("")
    end
  end

  def test_unmarshal_deflated
    str = deflate(Marshal.dump("abc"))
    assert_equal "abc", unmarshaled_deflated(str)
  end

  def test_detect_unicode_bom
    path = File.expand_path("../fixtures/encoding/ascii.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 17, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 17, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf8.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 20, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 20, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf8_bom.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 23, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 20, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf8_bom.js", __FILE__)
    str = File.binread(path)
    str.force_encoding(Encoding::UTF_8)
    assert_equal 23, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 20, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf16le.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 38, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 36, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf16le.js", __FILE__)
    str = File.binread(path)
    str.force_encoding(Encoding::UTF_16LE)
    assert_equal 38, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 36, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf16be.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 38, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_16BE, str.encoding
    assert_equal 36, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf32le.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 76, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_32LE, str.encoding
    assert_equal 72, str.bytesize

    path = File.expand_path("../fixtures/encoding/utf32be.js", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 76, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_32BE, str.encoding
    assert_equal 72, str.bytesize
  end

  def test_detect_css_charset
    path = File.expand_path("../fixtures/encoding/utf8-charset.css", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 38, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 21, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf8-charset.css", __FILE__)
    str = File.binread(path)
    str.force_encoding(Encoding::UTF_8)
    assert_equal 38, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 21, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf16le-charset.css", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 82, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 42, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf16le-charset.css", __FILE__)
    str = File.binread(path)
    str.force_encoding(Encoding::UTF_16LE)
    assert_equal 82, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 42, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf16le-bom-charset.css", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 84, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 42, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)
  end

  def test_detect_html_charset
    assert_equal Encoding.default_external, Encoding::UTF_8

    path = File.expand_path("../fixtures/encoding/utf8-charset.html", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 10, str.bytesize
    str = detect_html(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 10, str.bytesize
    assert_equal "<p>☃</p>", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf8_bom.html", __FILE__)
    str = File.binread(path)
    str.force_encoding(Encoding::UTF_8)
    assert_equal 13, str.bytesize
    str = detect_html(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 10, str.bytesize
    assert_equal "<p>☃</p>", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf16le.html", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 18, str.bytesize
    str = detect_html(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 16, str.bytesize
    assert_equal "<p>☃</p>", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf16be.html", __FILE__)
    str = File.binread(path)
    str.force_encoding(Encoding::UTF_16BE)
    assert_equal 18, str.bytesize
    str = detect_html(str)
    assert_equal Encoding::UTF_16BE, str.encoding
    assert_equal 16, str.bytesize
    assert_equal "<p>☃</p>", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf32be.html", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 36, str.bytesize
    str = detect_html(str)
    assert_equal Encoding::UTF_32BE, str.encoding
    assert_equal 32, str.bytesize
    assert_equal "<p>☃</p>", str.encode(Encoding::UTF_8)

    path = File.expand_path("../fixtures/encoding/utf32le.html", __FILE__)
    str = File.binread(path)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 36, str.bytesize
    str = detect_html(str)
    assert_equal Encoding::UTF_32LE, str.encoding
    assert_equal 32, str.bytesize
    assert_equal "<p>☃</p>", str.encode(Encoding::UTF_8)
  end
end
