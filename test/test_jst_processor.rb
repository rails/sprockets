require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/jst_processor'

class TestJstProcessor < MiniTest::Test
  def test_export_js_template_in_JST
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

  def test_export_js_template_in_TEMPLATES
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
