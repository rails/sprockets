# encoding: utf-8
require "sprockets_test"

class EncodingUtilsTest < Sprockets::TestCase
  include Sprockets::EncodingUtils

  test "detect unicode bom" do
    str = File.binread(fixture_path('encoding/ascii.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 17, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 17, str.bytesize

    str = File.binread(fixture_path('encoding/utf8.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 20, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 20, str.bytesize

    str = File.binread(fixture_path('encoding/utf8_bom.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 23, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 20, str.bytesize

    str = File.binread(fixture_path('encoding/utf8_bom.js'))
    str.force_encoding(Encoding::UTF_8)
    assert_equal 23, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 20, str.bytesize

    str = File.binread(fixture_path('encoding/utf16le.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 38, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 36, str.bytesize

    str = File.binread(fixture_path('encoding/utf16le.js'))
    str.force_encoding(Encoding::UTF_16LE)
    assert_equal 38, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 36, str.bytesize

    str = File.binread(fixture_path('encoding/utf16be.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 38, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_16BE, str.encoding
    assert_equal 36, str.bytesize

    str = File.binread(fixture_path('encoding/utf32le.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 76, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_32LE, str.encoding
    assert_equal 72, str.bytesize

    str = File.binread(fixture_path('encoding/utf32be.js'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 76, str.bytesize
    str = detect_unicode_bom(str)
    assert_equal Encoding::UTF_32BE, str.encoding
    assert_equal 72, str.bytesize
  end

  test "detect css charset" do
    str = File.binread(fixture_path('encoding/utf8-charset.css'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 38, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 21, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    str = File.binread(fixture_path('encoding/utf8-charset.css'))
    str.force_encoding(Encoding::UTF_8)
    assert_equal 38, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_8, str.encoding
    assert_equal 21, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    str = File.binread(fixture_path('encoding/utf16le-charset.css'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 82, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 42, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    str = File.binread(fixture_path('encoding/utf16le-charset.css'))
    str.force_encoding(Encoding::UTF_16LE)
    assert_equal 82, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 42, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)

    str = File.binread(fixture_path('encoding/utf16le-bom-charset.css'))
    assert_equal Encoding::BINARY, str.encoding
    assert_equal 84, str.bytesize
    str = detect_css(str)
    assert_equal Encoding::UTF_16LE, str.encoding
    assert_equal 42, str.bytesize
    assert_equal "\n\nh1 { color: red; }\n", str.encode(Encoding::UTF_8)
  end
end

class AssetEncodingTest < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.append_path(fixture_path('encoding'))
  end

  test "read ASCII asset" do
    data = @env['ascii.js'].to_s
    assert_equal "var foo = \"bar\";\n", data
    assert_equal Encoding::UTF_8, data.encoding
  end

  test "read UTF-8 asset" do
    data = @env['utf8.js'].to_s
    assert_equal "var snowman = \"☃\";\n", data
    assert_equal Encoding::UTF_8, data.encoding
  end

  test "read UTF-8 asset with BOM" do
    data = @env['utf8_bom.js'].to_s
    assert_equal "var snowman = \"☃\";\n", data
    assert_equal Encoding::UTF_8, data.encoding
  end

  test "read UTF-16 asset" do
    data = @env['utf16le.js'].to_s
    assert_equal "var snowman = \"☃\";\n", data
    assert_equal Encoding::UTF_8, data.encoding
  end

  test "read ASCII + UTF-8 concatation asset" do
    data = @env['ascii_utf8.js'].to_s
    assert_equal "var foo = \"bar\";\nvar snowman = \"\342\230\203\";\n\n\n",
      data
    assert_equal Encoding::UTF_8, data.encoding
  end

  test "read static BINARY asset" do
    data = @env['binary.png'].to_s
    assert_equal "\x89PNG\r\n\x1A\n\x00\x00\x00".force_encoding("BINARY"),
      data[0..10]
    assert_equal Encoding::BINARY, data.encoding
  end

  test "read processed BINARY asset" do
    @env.register_postprocessor('image/png', :noop_processor) { |context, data| data }
    data = @env['binary.png'].to_s
    assert_equal "\x89PNG\r\n\x1A\n\x00\x00\x00".force_encoding("BINARY"),
      data[0..10]
    assert_equal Encoding::BINARY, data.encoding
  end

  test "read css asset with charset" do
    expected = "\n\nh1 { color: red; }\n"
    assert_equal expected, @env['utf8-charset.css'].to_s
    assert_equal expected, @env['utf16le-charset.css'].to_s
    assert_equal expected, @env['utf16le-bom-charset.css'].to_s
  end

  test "read file with content type" do
    data = @env.read_file(fixture_path('encoding/ascii.js'), 'application/javascript')
    assert_equal "var foo = \"bar\";\n", data
    assert_equal Encoding::UTF_8, data.encoding

    data = @env.read_file(fixture_path('encoding/utf16le-charset.css'), 'text/css')
    assert_equal "\n\nh1 { color: red; }\n", data
    assert_equal Encoding::UTF_8, data.encoding
  end
end

class BinaryEncodingUtilsTest < Sprockets::TestCase
  include Sprockets::EncodingUtils

  test "deflate" do
    output = deflate("foobar")
    assert_equal 8, output.length
    assert_equal [75, 203, 207, 79, 74, 44, 2, 0], output.bytes.take(8)
  end

  test "gzip" do
    output = gzip("foobar")
    assert_equal 26, output.length
    assert_equal [31, 139, 8, 0, 1, 0, 0, 0], output.bytes.take(8)
  end

  test "base64" do
    assert_equal "Zm9vYmFy", base64("foobar")
  end
end
