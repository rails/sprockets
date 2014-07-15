require 'sprockets_test'
require 'sprockets/jst_processor'

class TestJstProcessor < Sprockets::TestCase
  test "export js template in JST" do
    input = {
      name: 'users/show',
      content_type: 'application/javascript',
      data: "function(obj) {\n  return 'Hello, '+obj.name;\n}",
      cache: Sprockets::Cache.new
    }
    output = <<-EOS
(function() { this.JST || (this.JST = {}); this.JST["users/show"] = function(obj) {
    return 'Hello, '+obj.name;
  };
}).call(this);
    EOS
    assert_equal output, Sprockets::JstProcessor.call(input)
  end

  test "export js template in TEMPLATES" do
    input = {
      name: 'users/show',
      content_type: 'application/javascript',
      data: "function(obj) {\n  return 'Hello, '+obj.name;\n}",
      cache: Sprockets::Cache.new
    }
    output = <<-EOS
(function() { this.TEMPLATES || (this.TEMPLATES = {}); this.TEMPLATES["users/show"] = function(obj) {
    return 'Hello, '+obj.name;
  };
}).call(this);
    EOS
    assert_equal output, Sprockets::JstProcessor.new(namespace: 'this.TEMPLATES').call(input)
  end
end
