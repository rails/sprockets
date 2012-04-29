require 'test/unit'
require 'sprockets/vlq'

class TestVLQ < Test::Unit::TestCase
  TESTS = {
    'A'          => [0],
    'C'          => [1],
    'D'          => [-1],
    'E'          => [2],
    'F'          => [-2],
    'K'          => [5],
    'L'          => [-5],
    'w+B'        => [1000],
    'x+B'        => [-1000],
    'gqjG'       => [100000],
    'hqjG'       => [-100000],
    'AAgBC'      => [0, 0, 16, 1],
    'AAgCgBC'    => [0, 0, 32, 16, 1],
    'DFLx+BhqjG' => [-1, -2, -5, -1000, -100000],
    'CEKw+BgqjG' => [1, 2, 5, 1000, 100000],
  }

  def test_encode
    TESTS.each do |str, int|
      assert_equal str, Sprockets::VLQ.encode(int)
    end
  end

  def test_decode
    TESTS.each do |str, int|
      assert_equal int, Sprockets::VLQ.decode(str)
    end
  end

  def test_encode_decode
    (-255..255).each do |int|
      assert_equal [int], Sprockets::VLQ.decode(Sprockets::VLQ.encode([int]))
    end
  end
end
