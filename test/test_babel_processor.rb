# frozen_string_literal: true
require 'sprockets_test'
require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/babel_processor'

class TestBabelProcessor < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new
    @env.append_path File.expand_path("../fixtures", __FILE__)
  end

  def test_not_raise_100k_error
    input = {
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: File.read(File.expand_path('../fixtures/asset/100k.js', __FILE__)),
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
    }

    #should not raise error
    Sprockets::BabelProcessor.call(input)
  end

  def test_compile_es6_features_to_es5
    input = {
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "const square = (n) => n * n",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
    }

    assert js = Sprockets::BabelProcessor.call(input)[:data]
    assert_match(/var square/, js)
    assert_match(/function/, js)
  end

  def test_transform_arrow_function
    input = {
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "var square = (n) => n * n",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
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
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'common').call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
require("foo");
    JS
  end

  def test_amd_modules
    input = {
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'amd').call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
define(["exports", "foo"], function (exports, _foo) {});
    JS
  end

  def test_amd_modules_with_ids
    input = {
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
    }

    assert js = Sprockets::BabelProcessor.new('modules' => 'amd', 'moduleIds' => true).call(input)[:data]
    assert_equal <<-JS.chomp, js.strip
define("mod", ["exports", "foo"], function (exports, _foo) {});
    JS
  end

  def test_system_modules
    input = {
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
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
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod.source-XYZ.es6"
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
      environment: @env,
      content_type: 'application/ecmascript-6',
      data: "import \"foo\";",
      metadata: {},
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/mod1.es6", __FILE__),
      cache: Sprockets::Cache.new,
      source_path: "mod1.source-XYZ.es6"
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

  def test_cache_key
    assert Sprockets::BabelProcessor.cache_key

    amd_processor_1 = Sprockets::BabelProcessor.new('modules' => 'amd')
    amd_processor_2 = Sprockets::BabelProcessor.new('modules' => 'amd')
    assert_equal amd_processor_1.cache_key, amd_processor_2.cache_key

    system_processor = Sprockets::BabelProcessor.new('modules' => 'system')
    refute_equal amd_processor_1.cache_key, system_processor.cache_key
  end
end
