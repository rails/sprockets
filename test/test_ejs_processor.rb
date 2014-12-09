require 'sprockets_test'
require 'sprockets/ejs_processor'

class TestEjsProcessor < Sprockets::TestCase
  test "compile ejs template to js" do
    input = {
      content_type: 'application/javascript',
      data: "<span>Hello, <%= name %></p>",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::EjsProcessor.call(input).match(/<span>Hello, /)
  end
end
