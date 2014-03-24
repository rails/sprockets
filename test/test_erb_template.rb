require 'sprockets_test'
require 'sprockets/erb_template'

class TestERBTemplate < Sprockets::TestCase
  test "compile js erb template" do
    environment = Sprockets::Environment.new
    context = environment.context_class.new(environment, "foo", "foo.js.erb")

    input = {
      environment: environment,
      context: context,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "var data = <%= JSON.generate({foo: true}) %>;",
      cache: Sprockets::CacheWrapper.wrap(nil)
    }
    output = "var data = {\"foo\":true};"
    assert_equal output, Sprockets::ERBTemplate.call(input)
  end
end
