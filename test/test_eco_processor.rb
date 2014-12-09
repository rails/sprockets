require 'sprockets_test'
require 'sprockets/eco_processor'

class TestEcoProcessor < Sprockets::TestCase
  test "compile eco template to js" do
    input = {
      content_type: 'application/javascript',
      data: "<span>Hello, <%= name %></p>",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::EcoProcessor.call(input).match(/<span>Hello, /)
  end
end
