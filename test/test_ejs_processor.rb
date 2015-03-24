require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/ejs_processor'

class TestEjsProcessor < MiniTest::Test
  def test_compile_ejs_template_to_js
    input = {
      content_type: 'application/javascript',
      data: "<span>Hello, <%= name %></p>",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::EjsProcessor.call(input).match(/<span>Hello, /)
  end

  def test_cache_key
    assert Sprockets::EjsProcessor.cache_key
  end
end
