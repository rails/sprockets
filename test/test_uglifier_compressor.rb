require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/uglifier_compressor'

class TestUglifierCompressor < MiniTest::Test
  def test_compress_javascript
    input = {
      content_type: 'application/javascript',
      data: "/* Copyright Rails */\nfunction foo() {\n  return true;\n}",
      cache: Sprockets::Cache.new
    }
    output = "function foo(){return!0}"
    assert_equal output, Sprockets::UglifierCompressor.call(input)
  end

  def test_cache_key
    assert Sprockets::UglifierCompressor.cache_key
  end
end
