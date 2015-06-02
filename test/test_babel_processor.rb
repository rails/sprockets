require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/babel_processor'

class TestBabelProcessor < MiniTest::Test
  def test_compile_es6_features_to_es5
    input = {
      content_type: 'application/ecmascript-6',
      data: "const square = (n) => n * n",
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.call(input)
    assert_match(/var square/, js)
    assert_match(/function/, js)
  end

  def test_transform_arrow_function
    input = {
      content_type: 'application/ecmascript-6',
      data: "var square = (n) => n * n",
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.call(input)
    assert_equal <<-JS.chomp, js.strip
var square = function square(n) {
  return n * n;
};
    JS
  end

  def test_common_modules
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'common').call(input)
    assert_equal <<-JS.chomp, js.strip
require("foo");
    JS
  end

  def test_amd_modules
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'amd').call(input)
    assert_equal <<-JS.chomp, js.strip
define(["exports", "foo"], function (exports, _foo) {});
    JS
  end

  def test_amd_modules_with_ids
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'amd', 'moduleIds' => true).call(input)
    assert_equal <<-JS.chomp, js.strip
define("mod", ["exports", "foo"], function (exports, _foo) {});
    JS
  end

  def test_system_modules
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'system').call(input)
    assert_equal <<-JS.chomp, js.strip
System.register(["foo"], function (_export) {
  return {
    setters: [function (_foo) {}],
    execute: function () {}
  };
});
    JS
  end

  def test_system_modules_with_ids
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'system', 'moduleIds' => true).call(input)
    assert_equal <<-JS.chomp, js.strip
System.register("mod", ["foo"], function (_export) {
  return {
    setters: [function (_foo) {}],
    execute: function () {}
  };
});
    JS
  end
end
