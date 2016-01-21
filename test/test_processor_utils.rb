require 'minitest/autorun'
require 'sprockets/processor_utils'

require 'sprockets/cache'
require 'sprockets/coffee_script_processor'
require 'sprockets/uglifier_compressor'

require 'sprockets_test'

class TestCallingProcessors < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.append_path fixture_path('default')
  end

  def test_charset_supersedes_default_when_nil
    processor = Proc.new do |input|
      {data: input[:data], charset: nil}
    end
    @env.register_processor('image/png' , processor)
    asset = @env['troll.png']
    assert_equal nil, asset.charset
  ensure
    @env.unregister_preprocessor('image/png' , processor)
  end

  def test_charset_supersedes_default
    processor = Proc.new do |input|
      {data: input[:data], charset: 'foo'}
    end
    @env.register_processor('image/png' , processor)
    asset = @env['troll.png']
    assert_equal 'foo', asset.charset
  ensure
    @env.unregister_preprocessor('image/png' , processor)
  end
end

class TestProcessorUtils < MiniTest::Test
  include Sprockets::ProcessorUtils

  class Processor
    def initialize(cache_key = nil, &block)
      @cache_key, @proc = cache_key, block
    end

    attr_reader :cache_key

    def call(*args)
      @proc.call(*args)
    end
  end

  def test_call_nothing
    a = proc {}

    input = { data: " " }.freeze
    assert result = call_processor(a, input)
    assert_equal " ", result[:data]
  end

  def test_call_function
    a = proc { |input| { data: input[:data] + ",a" } }

    input = { data: " " }.freeze
    assert result = call_processor(a, input)
    assert_equal " ,a", result[:data]
  end

  def test_call_single_function
    a = proc { |input| { data: input[:data] + ",a" } }

    input = { data: " " }.freeze
    assert result = call_processors([a], input)
    assert_equal " ,a", result[:data]
  end

  def test_call_hash_return
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }

    input = { data: " " }.freeze
    assert result = call_processors([b, a], input)
    assert_equal " ,a,b", result[:data]
  end

  def test_call_string_return
    a = proc { |input| input[:data] + ",a" }
    b = proc { |input| input[:data] + ",b" }

    input = { data: " " }.freeze
    assert result = call_processors([b, a], input)
    assert_equal " ,a,b", result[:data]
  end

  def test_call_noop_return
    a = proc { |input| input[:data] + ",a" }
    b = proc { |input| nil }

    input = { data: " " }.freeze
    assert result = call_processors([a, b], input)
    assert_equal " ,a", result[:data]
    assert result = call_processors([b, a], input)
    assert_equal " ,a", result[:data]
  end

  def test_call_metadata
    a = proc { |input| { a: true } }
    b = proc { |input| { b: true } }

    input = {}
    assert result = call_processors([a, b], input)
    assert result[:a]
    assert result[:b]
  end

  def test_call_metadata_merge
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }

    input = { metadata: { trace: [] }.freeze }.freeze
    assert result = call_processors([b, a], input)
    assert_equal [:a, :b], result[:trace]
  end

  def test_compose_nothing
    a = compose_processors()

    input = { data: " " }.freeze
    assert result = a.call(input)
    assert_equal " ", result[:data]
  end

  def test_compose_single_function
    a = proc { |input| { data: input[:data] + ",a" } }
    b = compose_processors(a)

    input = { data: " " }.freeze
    assert result = b.call(input)
    assert_equal " ,a", result[:data]
  end

  def test_compose_hash_return
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }
    c = compose_processors(b, a)

    input = { data: " " }.freeze
    assert result = c.call(input)
    assert_equal " ,a,b", result[:data]
  end

  def test_compose_string_return
    a = proc { |input| input[:data] + ",a" }
    b = proc { |input| input[:data] + ",b" }
    c = compose_processors(b, a)

    input = { data: " " }.freeze
    assert result = c.call(input)
    assert_equal " ,a,b", result[:data]
  end

  def test_compose_noop_return
    a = proc { |input| input[:data] + ",a" }
    b = proc { |input| nil }
    c = compose_processors(a, b)
    d = compose_processors(b, a)

    input = { data: " " }.freeze
    assert result = c.call(input)
    assert_equal " ,a", result[:data]
    assert result = d.call(input)
    assert_equal " ,a", result[:data]
  end

  def test_compose_metadata
    a = proc { |input| { a: true } }
    b = proc { |input| { b: true } }
    c = compose_processors(a, b)

    input = {}
    assert result = c.call(input)
    assert result[:a]
    assert result[:b]
  end

  def test_compose_metadata_merge
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }
    c = compose_processors(b, a)

    input = { metadata: { trace: [] }.freeze }.freeze
    assert result = c.call(input)
    assert_equal [:a, :b], result[:trace]
  end

  def test_multiple_functional_compose
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }
    c = proc { |input| { data: input[:data] + ",c" } }
    d = proc { |input| { data: input[:data] + ",d" } }
    e = compose_processors(d, compose_processors(c, compose_processors(b, compose_processors(a))))

    input = { data: " " }.freeze
    assert result = e.call(input)
    assert_equal " ,a,b,c,d", result[:data]
  end

  def test_multiple_functional_compose_metadata
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }
    c = proc { |input| { trace: input[:metadata][:trace] + [:c] } }
    d = proc { |input| { trace: input[:metadata][:trace] + [:d] } }
    e = compose_processors(d, compose_processors(c, compose_processors(b, compose_processors(a))))

    input = { metadata: { trace: [].freeze }.freeze }.freeze
    assert result = e.call(input)
    assert_equal [:a, :b, :c, :d], result[:trace]
  end

  def test_multiple_array_compose
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }
    c = proc { |input| { data: input[:data] + ",c" } }
    d = proc { |input| { data: input[:data] + ",d" } }
    e = compose_processors(d, c, b, a)

    input = { data: " " }
    assert result = e.call(input)
    assert_equal " ,a,b,c,d", result[:data]
  end

  def test_multiple_array_compose_metadata
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }
    c = proc { |input| { trace: input[:metadata][:trace] + [:c] } }
    d = proc { |input| { trace: input[:metadata][:trace] + [:d] } }
    e = compose_processors(d, c, b, a)

    input = { metadata: { trace: [].freeze }.freeze }.freeze
    assert result = e.call(input)
    assert_equal [:a, :b, :c, :d], result[:trace]
  end

  def test_compose_coffee_and_uglifier
    processor = compose_processors(Sprockets::UglifierCompressor, Sprockets::CoffeeScriptProcessor)

    input = {
      content_type: 'application/javascript',
      data: "self.square = (n) -> n * n",
      cache: Sprockets::Cache.new
    }.freeze
    assert result = processor.call(input)
    assert_match "self.square=function", result[:data]
  end

  def test_bad_processor_return_type
    a = proc { |input| Object.new }
    b = compose_processors(a)

    input = { data: " " }.freeze
    assert_raises(TypeError) do
      b.call(input)
    end
  end

  def test_compose_class_processors
    a = Processor.new { |input| { data: input[:data] + ",a" } }
    b = Processor.new { |input| { data: input[:data] + ",b" } }
    c = compose_processors(b, a)

    input = { data: " " }.freeze
    assert result = c.call(input)
    assert_equal " ,a,b", result[:data]
  end

  def test_compose_processors_cache_keys
    a = Processor.new("a")
    b = Processor.new("b")
    c = compose_processors(b, a)

    assert_equal "a", a.cache_key
    assert_equal "b", b.cache_key
    assert_equal ["b", "a"], c.cache_key
  end

  def test_compose_processors_missing_cache_keys
    a = Processor.new("a")
    b = proc {}
    c = Processor.new("c")
    e = compose_processors(c, b, a)

    assert_equal "a", a.cache_key
    assert_equal "c", c.cache_key
    assert_equal ["c", nil, "a"], e.cache_key
  end

  def test_multiple_array_compose_cache_keys
    a = Processor.new("a")
    b = Processor.new("b")
    c = Processor.new("c")
    d = Processor.new("d")
    e = compose_processors(d, c, b, a)

    assert_equal "a", a.cache_key
    assert_equal "b", b.cache_key
    assert_equal "c", c.cache_key
    assert_equal "d", d.cache_key
    assert_equal ["d", "c", "b", "a"], e.cache_key
  end

  def test_multiple_functional_compose_cache_keys
    a = Processor.new("a")
    b = Processor.new("b")
    c = Processor.new("c")
    d = Processor.new("d")
    e = compose_processors(d, compose_processors(c, compose_processors(b, compose_processors(a))))

    assert_equal "a", a.cache_key
    assert_equal "b", b.cache_key
    assert_equal "c", c.cache_key
    assert_equal "d", d.cache_key
    assert_equal ["d", ["c", ["b", ["a"]]]], e.cache_key
  end

  def test_validate_processor_result
    validate_processor_result!({data: "hello"})
    validate_processor_result!({data: "hello", foo: nil})
    validate_processor_result!({data: "hello", foo: 1})
    validate_processor_result!({data: "hello", foo: "bye"})
    validate_processor_result!({data: "hello", foo: :bye})
    validate_processor_result!({data: "hello", foo: [1, 2, 3]})
    validate_processor_result!({data: "hello", foo: Set.new([1, 2, 3])})
    validate_processor_result!({data: "hello", foo: {bar: 1}})

    my_string = Class.new(String)
    assert_raises(TypeError) { validate_processor_result!(nil) }
    assert_raises(TypeError) { validate_processor_result!({}) }
    assert_raises(TypeError) { validate_processor_result!({data: 123}) }
    assert_raises(TypeError) { validate_processor_result!({data: "hello", "foo" => 1}) }
    assert_raises(TypeError) { validate_processor_result!({data: my_string.new("hello")}) }
    assert_raises(TypeError) { validate_processor_result!({data: "hello", foo: Object.new}) }
    assert_raises(TypeError) { validate_processor_result!({data: "hello", foo: [Object.new]}) }
    assert_raises(TypeError) { validate_processor_result!({data: "hello", foo: Set.new([Object.new])}) }
    assert_raises(TypeError) { validate_processor_result!({data: "hello", foo: {bar: Object.new}}) }
  end
end
