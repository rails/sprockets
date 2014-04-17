# -*- coding: utf-8 -*-
require 'sprockets_test'
require 'sprockets/utils'

class TestUtils < Sprockets::TestCase
  include Sprockets::Utils

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

  test "hexdigest" do
    assert_equal "15e1d872b31958c396eaac1d61b9e46aa2f5531f", hexdigest(nil)
    assert_equal "a88ea7cfcdafcd734a5e64234ba924227207df8c", hexdigest(true)
    assert_equal "0d9c2b81e82b07d10af56e40a76d70f4b979549b", hexdigest(false)
    assert_equal "58d7702df212c54f0a1f1f51b59f5ae988232ed8", hexdigest(42)
    assert_equal "fb993f056be461ce93d6a846692c9fdfceb50b21", hexdigest("foo")
    assert_equal "311a5592f7f7decd9b4b19d1350207a415c00608", hexdigest(:foo)
    assert_equal "107004472b7ba4e5e31f3082ee1fb5a1239eec61", hexdigest([])
    assert_equal "963e559076890aca4467f5b6abad3423808d3d17", hexdigest(["foo"])
    assert_equal "05a451be0a83da8f6fdf90eab8afdb9bf6a5dc4d", hexdigest({"foo" => "bar"})

    assert_raises(TypeError) do
      hexdigest(Object.new)
    end
  end
end
