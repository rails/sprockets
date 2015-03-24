require 'minitest/autorun'
require 'sprockets/cache'
require 'sprockets/eco_processor'

class TestEcoProcessor < MiniTest::Test
  def test_compile_eco_template_to_js
    input = {
      content_type: 'application/javascript',
      data: "<span>Hello, <%= name %></p>",
      cache: Sprockets::Cache.new
    }
    assert Sprockets::EcoProcessor.call(input).match(/<span>Hello, /)
  end

  def test_cache_key
    assert Sprockets::EcoProcessor.cache_key
  end
end
