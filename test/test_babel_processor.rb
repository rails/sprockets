require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/babel_processor'

class TestBabelProcessor < MiniTest::Test
  def test_compile_es6_features_to_es5
    input = {
      content_type: 'application/ecmascript-6',
      data: "const square = (n) => n * n",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.call(input)[:data]
    assert_match(/var square/, js)
    assert_match(/function/, js)
  end

  def test_transform_arrow_function
    input = {
      content_type: 'application/ecmascript-6',
      data: "var square = (n) => n * n",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.call(input)[:data]
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
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'common').call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
require("foo");
    JS
  end

  def test_amd_modules
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'amd').call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
define(["exports", "foo"], function (exports, _foo) {});
    JS
  end

  def test_amd_modules_with_ids
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'amd', 'moduleIds' => true).call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
define("mod", ["exports", "foo"], function (exports, _foo) {});
    JS
  end

  def test_system_modules
    input = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'system').call(input)[:data]
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
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'system', 'moduleIds' => true).call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
System.register("mod", ["foo"], function (_export) {
  return {
    setters: [function (_foo) {}],
    execute: function () {}
  };
});
    JS
  end

  def test_caching_takes_filename_into_account
    mod1 = {
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod1.es6", __FILE__),
      cache: Sprockets::Cache.new
    }

    mod2 = mod1.dup
    mod2[:filename] = File.expand_path("../fixtures/mod2.es6", __FILE__)

    assert js1 = Sprockets::BabelProcessor.new('modules' => 'system', 'moduleIds' => true).call(mod1)[:data]
    assert_equal <<-JS.chomp, js1.to_s.strip
System.register("mod1", ["foo"], function (_export) {
  return {
    setters: [function (_foo) {}],
    execute: function () {}
  };
});
    JS

    assert js2 = Sprockets::BabelProcessor.new('modules' => 'system', 'moduleIds' => true).call(mod2)[:data]
    assert_equal <<-JS.chomp, js2.to_s.strip
System.register("mod2", ["foo"], function (_export) {
  return {
    setters: [function (_foo) {}],
    execute: function () {}
  };
});
    JS
  end
end
