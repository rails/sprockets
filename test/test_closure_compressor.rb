require 'sprockets_test'
require 'sprockets/closure_compressor'

class TestClosureCompressor < Sprockets::TestCase
  test "compress javascript" do
    input = {
      :data => "function foo() {\n  return true;\n}"
    }
    output = "function foo(){return!0};\n"
    assert_equal output, Sprockets::ClosureCompressor.call(input)
  end
end
