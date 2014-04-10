require 'sprockets_test'
require 'sprockets/erb_template'

class TestERBTemplate < Sprockets::TestCase
  test "compile js erb template" do
    environment = Sprockets::Environment.new

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "var data = <%= JSON.generate({foo: true}) %>;",
      cache: Sprockets::Cache.new
    }
    input[:context] = environment.context_class.new(input)

    output = "var data = {\"foo\":true};"
    assert_equal output, Sprockets::ERBTemplate.call(input)
  end
end
