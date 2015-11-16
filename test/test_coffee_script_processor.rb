require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/coffee_script_processor'

class TestCoffeeScriptProcessor < MiniTest::Test
  def test_compile_coffee_script_template_to_js
    input = {
      content_type: 'application/javascript',
      data: 'square = (n) -> n * n',
      name: 'squared',
      cache: Sprockets::Cache.new,
      metadata: { mapping: [] }
    }
    result = Sprockets::CoffeeScriptProcessor.call(input)
    assert result[:data].match(/var square/)
    assert_equal 19, result[:map].size
    assert_equal [], result[:map].map { |m| m[:source] }.uniq.compact
  end

  def test_cache_key
    assert Sprockets::CoffeeScriptProcessor.cache_key
  end
end
