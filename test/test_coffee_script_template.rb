require 'sprockets_test'
require 'sprockets/coffee_script_template'

class TestCoffeeScriptTemplate < Sprockets::TestCase
  test "compile coffee-script template to js" do
    input = {
      content_type: 'application/javascript',
      data: "square = (n) -> n * n",
      cache: Sprockets::CacheWrapper.wrap(nil)
    }
    assert Sprockets::CoffeeScriptTemplate.call(input).match(/var square/)
  end
end
