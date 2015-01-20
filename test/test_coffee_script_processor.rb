require 'sprockets_test'
require 'sprockets/coffee_script_processor'

class TestCoffeeScriptProcessor < Sprockets::TestCase
  test "compile coffee-script template to js" do
    input = {
      content_type: 'application/javascript',
      data: "square = (n) -> n * n",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::CoffeeScriptProcessor.call(input).match(/var square/)
  end

  test "cache key" do
    assert Sprockets::CoffeeScriptProcessor.cache_key
  end
end
