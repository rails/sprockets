# -*- coding: utf-8 -*-
require 'sprockets_test'
require 'sprockets/fileutils'

class TestUtils < Sprockets::TestCase
  include Sprockets::FileUtils

  test "read unicode" do
    assert_equal "var foo = \"bar\";\n",
      read_unicode(fixture_path('encoding/ascii.js'))
    assert_equal "var snowman = \"☃\";",
      read_unicode(fixture_path('encoding/utf8.js'))
    assert_equal "var snowman = \"☃\";",
      read_unicode(fixture_path('encoding/utf8_bom.js'))

    assert_raises Sprockets::EncodingError do
      read_unicode(fixture_path('encoding/utf16.js'))
    end
  end
end
