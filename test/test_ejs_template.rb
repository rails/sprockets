require 'sprockets_test'
require 'sprockets/ejs_template'

class TestEjsTemplate < Sprockets::TestCase
  test "compile ejs template to js" do
    input = {
      content_type: 'application/javascript',
      data: "<span>Hello, <%= name %></p>",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::EjsTemplate.call(input).match(/<span>Hello, /)
  end
end
