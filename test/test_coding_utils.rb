require "sprockets_test"

class CodingUtilsTest < Sprockets::TestCase
  include Sprockets::CodingUtils

  test "deflate" do
    output = deflate(["foo", "bar"])
    assert_equal 8, output.length
    assert_equal [75, 203, 207, 79, 74, 44, 2, 0], output.bytes[0, 8]
  end

  test "gzip" do
    output = gzip(["foo", "bar"])
    assert_equal 25, output.length
    assert_equal [31, 139, 8, 0], output.bytes[0, 4]
  end

  test "base64" do
    assert_equal "Zm9vYmFy", base64(["foo", "bar"])
  end
end
