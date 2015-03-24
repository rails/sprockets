require 'minitest/autorun'
require 'sprockets/source_map/mapping'

class TestSourceMapping < MiniTest::Test
  Mapping = Sprockets::SourceMap::Mapping

  def setup
    @mapping = Mapping.new("a.js", [1, 5], [2, 0], "foo")
  end

  def test_equal
    assert @mapping.dup == @mapping
    assert Mapping.new("b.js", [1, 5], [2, 0], "foo") != @mapping
    assert Mapping.new("a.js", [1, 5], [2, 0], "bar") != @mapping
    assert Mapping.new("a.js", [1, 6], [2, 0], "foo") != @mapping
    assert Mapping.new("a.js", [1, 5], [3, 0], "foo") != @mapping
  end

  def test_source
    assert_equal "a.js", @mapping.source
  end

  def test_generated
    assert_equal [1, 5], @mapping.generated
  end

  def test_original
    assert_equal [2, 0], @mapping.original
  end

  def test_name
    assert_equal "foo", @mapping.name
  end

  def test_to_s
    assert_equal "1:5->a.js@2:0#foo", @mapping.to_s
  end
end
