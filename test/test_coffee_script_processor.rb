# frozen_string_literal: true
require 'sprockets_test'
require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/coffee_script_processor'
require 'sprockets/source_map_utils'

class TestCoffeeScriptProcessor < Minitest::Test
  def setup
    @env = Sprockets::Environment.new
    @env.append_path File.expand_path("../fixtures", __FILE__)
  end

  def test_compile_coffee_script_template_to_js
    input = {
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/squared.coffee", __FILE__),
      content_type: 'application/javascript',
      environment: @env,
      data: "square = (n) -> n * n",
      name: 'squared',
      cache: Sprockets::Cache.new,
      metadata: { mapping: [] }
    }
    result = Sprockets::CoffeeScriptProcessor.call(input)
    assert result[:data].match(/var square/)
    assert_equal 13, Sprockets::SourceMapUtils.decode_source_map(result[:map])[:mappings].size
    assert_equal ["squared.coffee"], result[:map]["sources"]
    assert_nil result[:map]["sourcesContent"]
  end

  def test_changing_map_sources_for_files_with_same_content
    input = {
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/squared.coffee", __FILE__),
      content_type: 'application/javascript',
      environment: @env,
      data: "square = (n) -> n * n",
      name: 'squared',
      cache: Sprockets::Cache.new,
      metadata: { mapping: [] }
    }
    result = Sprockets::CoffeeScriptProcessor.call(input)
    assert_equal ["squared.source.coffee"], result[:map]["sources"]

    input[:filename] = File.expand_path("../fixtures/peterpan.coffee", __FILE__)

    result = Sprockets::CoffeeScriptProcessor.call(input)
    assert_equal ["peterpan.source.coffee"], result[:map]["sources"]
  end

  def test_cache_key
    assert Sprockets::CoffeeScriptProcessor.cache_key
  end
end
