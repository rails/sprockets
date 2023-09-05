# frozen_string_literal: true
require 'minitest/autorun'
require 'sprockets/cache'
unless RUBY_PLATFORM.include?('java')
  require 'sprockets/jsminc_compressor'

  class TestJSMincCompressor < Minitest::Test

    def test_compress_javascript
      input = {
        content_type: 'application/javascript',
        data: "function foo() {\n  return true;\n}",
        cache: Sprockets::Cache.new
      }
      output = "function foo(){return true;}"

      assert_equal output, Sprockets::JSMincCompressor.call(input)
    end

    def test_cache_key
      assert Sprockets::JSMincCompressor.cache_key
    end
  end
end