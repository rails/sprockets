require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/closure_compressor'

class TestClosureCompressor < MiniTest::Test
  def test_compress_javascript
    input = {
      data: "function foo() {\n  return true;\n}",
      cache: Sprockets::Cache.new
    }
    output = "function foo(){return!0};\n"

    begin
      assert_equal output, Sprockets::ClosureCompressor.call(input)
    rescue Closure::Error
      skip 'No Java runtime present'
    end
  end

  def test_cache_key
    assert Sprockets::ClosureCompressor.cache_key
  end
end
