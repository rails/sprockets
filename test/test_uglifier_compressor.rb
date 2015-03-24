require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/uglifier_compressor'

class TestUglifierCompressor < MiniTest::Test
  def test_compress_javascript
    input = {
      content_type: 'application/javascript',
      data: "function foo() {\n  return true;\n}",
      cache: Sprockets::Cache.new,
      metadata: {
        mapping: []
      }
    }
    output = "function foo(){return!0}"
    result = Sprockets::UglifierCompressor.call(input)
    assert_equal output, result[:data]
  end

  def test_cache_key
    assert Sprockets::UglifierCompressor.cache_key
  end
end
