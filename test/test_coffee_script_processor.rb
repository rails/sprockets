require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/coffee_script_processor'

class TestCoffeeScriptProcessor < MiniTest::Test
  def test_compile_coffee_script_template_to_js
    input = {
      content_type: 'application/javascript',
      data: "square = (n) -> n * n",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::CoffeeScriptProcessor.call(input).match(/var square/)
  end

  def test_cache_key
    assert Sprockets::CoffeeScriptProcessor.cache_key
  end
end
