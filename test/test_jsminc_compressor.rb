require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/jsminc_compressor'

class TestJSMincCompressor < MiniTest::Test

  def test_compress_javascript
    input = {
      content_type: 'application/javascript',
      data: "function foo() {\n  return true;\n}",
      cache: Sprockets::Cache.new
    }
    output = "function foo(){return true;}"

    assert_equal output, Sprockets::JSMincCompressor.call(input)
  end

  def test_cache_key
    assert Sprockets::JSMincCompressor.cache_key
  end
end