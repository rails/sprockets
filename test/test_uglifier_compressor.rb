# frozen_string_literal: true
require 'sprockets_test'
require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/uglifier_compressor'

class TestUglifierCompressor < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new
    @env.append_path File.expand_path("../fixtures", __FILE__)
  end

  def test_compress_javascript
    input = {
      environment: @env,
      load_path: File.expand_path("../fixtures", __FILE__),
      filename: File.expand_path("../fixtures/file.js", __FILE__),
      content_type: 'application/javascript',
      data: "function foo() {\n  return true;\n}",
      cache: Sprockets::Cache.new,
      metadata: {
        map: {
          "version" => 3,
          "file" => "test/file.js",
          "mappings" => "AAAA",
          "sources" => ["file.js"],
          "names" => []
        }
      }
    }
    output = "function foo(){return!0}"
    result = Sprockets::UglifierCompressor.call(input)
    assert_equal output, result[:data]
  end

  def test_cache_key
    assert Sprockets::UglifierCompressor.cache_key
  end
end
