require 'minitest/autorun'
require 'sprockets/source_map/mapping'
require 'sprockets/source_map/offset'

class TestSourceMapping < MiniTest::Test
  Mapping = Sprockets::SourceMap::Mapping
  Offset = Sprockets::SourceMap::Offset

  def setup
    @mapping = Mapping.new("a.js", Offset.new(1, 5), Offset.new(2, 0), "foo")
  end

  def test_equal
    assert @mapping.dup == @mapping
    assert Mapping.new("b.js", Offset.new(1, 5), Offset.new(2, 0), "foo") != @mapping
    assert Mapping.new("a.js", Offset.new(1, 5), Offset.new(2, 0), "bar") != @mapping
    assert Mapping.new("a.js", Offset.new(1, 6), Offset.new(2, 0), "foo") != @mapping
    assert Mapping.new("a.js", Offset.new(1, 5), Offset.new(3, 0), "foo") != @mapping
  end

  def test_source
    assert_equal "a.js", @mapping.source
  end

  def test_generated
    assert_equal Offset.new(1, 5), @mapping.generated
  end

  def test_original
    assert_equal Offset.new(2, 0), @mapping.original
  end

  def test_name
    assert_equal "foo", @mapping.name
  end

  def test_to_s
    assert_equal "1:5->a.js@2:0#foo", @mapping.to_s
  end

  def test_inspect
    assert_equal "#<Sprockets::SourceMap::Mapping source=\"a.js\" generated=1:5, original=2 name=\"foo\">", @mapping.inspect
  end
end
