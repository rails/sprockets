require 'sprockets_test'
require 'sprockets/closure_compressor'

class TestClosureCompressor < Sprockets::TestCase
  test "compress javascript" do
    input = {
      :data => "function foo() {\n  return true;\n}",
      :cache => Sprockets::Cache.new
    }
    output = "function foo(){return!0};\n"

    begin
      assert_equal output, Sprockets::ClosureCompressor.call(input)
    rescue Closure::Error
      skip "No Java runtime present"
    end
  end

  test "cache key" do
    assert Sprockets::ClosureCompressor.cache_key
  end
end
