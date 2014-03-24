require 'sprockets_test'
require 'sprockets/eco_template'

class TestEcoTemplate < Sprockets::TestCase
  test "compile eco template to js" do
    input = {
      content_type: 'application/javascript',
      data: "<span>Hello, <%= name %></p>",
      cache: Sprockets::CacheWrapper.wrap(nil)
    }
    assert Sprockets::EcoTemplate.call(input).match(/<span>Hello, /)
  end
end
