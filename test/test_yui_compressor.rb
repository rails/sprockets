require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/yui_compressor'

class TestYUICompressor < MiniTest::Test
  def test_compress_javascript
    input = {
      content_type: 'application/javascript',
      data: "function foo() {\n  return true;\n}",
      cache: Sprockets::Cache.new
    }
    output = "function foo(){return true};"

    begin
      assert_equal output, Sprockets::YUICompressor.call(input)
    rescue YUI::Compressor::RuntimeError
      skip "No Java runtime present"
    end
  end

  def test_compress_css
    input = {
      content_type: 'text/css',
      data: "h1 {\n  color: red;\n}\n",
      cache: Sprockets::Cache.new
    }
    output = "h1{color:red}"

    begin
      assert_equal output, Sprockets::YUICompressor.call(input)
    rescue YUI::Compressor::RuntimeError
      skip "No Java runtime present"
    end
  end

  def test_cache_key
    assert Sprockets::YUICompressor.cache_key
  end
end
