require 'minitest/autorun'
require 'sprockets/source_map/offset'

class TestSourceMapOffset < MiniTest::Test
  include Sprockets::SourceMap

  def setup
    @offset = Offset.new(1, 5)
  end

  def test_equal
    assert Offset.new(1, 5) == @offset
    assert Offset.new(1, 6) != @offset
    assert Offset.new(2, 5) != @offset
  end

  def test_from_array
    assert Offset.new(1, 5) == Offset.new([1, 5])
  end

  def test_from_offset
    assert @offset == Offset.new(@offset)
  end

  def test_line
    assert_equal 1, @offset.line
  end

  def test_column
    assert_equal 5, @offset.column
  end

  def test_to_s
    assert_equal "0", Offset.new(0, 0).to_s
    assert_equal "1", Offset.new(1, 0).to_s
    assert_equal "1:5", Offset.new(1, 5).to_s
  end

  def test_inspect
    assert_equal "#<Sprockets::SourceMap::Offset line=1, column=5>", @offset.inspect
  end

  def test_add_offset
    offset = @offset + Offset.new(2, 1)
    assert_equal 3, offset.line
    assert_equal 6, offset.column
  end

  def test_add_line
    offset = @offset + 5
    assert_equal 6, offset.line
    assert_equal 5, offset.column
  end

  def test_compare
    assert @offset < Offset.new(2, 0)
    assert @offset < Offset.new(1, 6)
    assert @offset > Offset.new(1, 4)
    assert @offset >= Offset.new(1, 5)
    assert @offset <= Offset.new(1, 5)
  end
end
