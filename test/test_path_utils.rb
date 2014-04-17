# -*- coding: utf-8 -*-
require 'sprockets_test'
require 'sprockets/path_utils'

class TestPathUtils < Sprockets::TestCase
  include Sprockets::PathUtils

  test "read unicode" do
    assert_equal "var foo = \"bar\";\n",
      read_unicode_file(fixture_path('encoding/ascii.js'))
    assert_equal "var snowman = \"☃\";",
      read_unicode_file(fixture_path('encoding/utf8.js'))
    assert_equal "var snowman = \"☃\";",
      read_unicode_file(fixture_path('encoding/utf8_bom.js'))

    assert_raises Sprockets::EncodingError do
      read_unicode_file(fixture_path('encoding/utf16.js'))
    end
  end

  test "atomic write without errors" do
    filename = "atomic.file"
    begin
      contents = "Atomic Text"
      atomic_write(filename, Dir.pwd) do |file|
        file.write(contents)
        assert !File.exist?(filename)
      end
      assert File.exist?(filename)
      assert_equal contents, File.read(filename)
    ensure
      File.unlink(filename) rescue nil
    end
  end
end
