require 'minitest/autorun'
require 'sprockets/utils'

class TestUtils < MiniTest::Test
  include Sprockets::Utils

  def test_duplicable_pre_ruby_2_4
    skip if RUBY_VERSION >= "2.4"

    objs = [nil, true, false, 1, "foo", :foo, [], {}]
    objs.each do |obj|
      begin
        obj.dup
      rescue TypeError
        refute duplicable?(obj), "can't dup: #{obj.inspect}"
      else
        assert duplicable?(obj), "can dup: #{obj.inspect}"
      end
    end
  end

  def test_duplicable_post_ruby_2_4
    skip if RUBY_VERSION < "2.4"

    objs = [nil, true, false, 1, "foo", :foo, [], {}]
    objs.each do |obj|
      begin
        obj.dup
      rescue TypeError
        refute duplicable?(obj), "can't dup: #{obj.inspect}"
      else
        assert duplicable?(obj), "can dup: #{obj.inspect}"
      end
    end
  end

  def test_hash_reassoc
    h = hash_reassoc({}.freeze, :foo) do |value|
      refute value
      nil
    end
    assert_equal({foo: nil}, h)
    assert h.frozen?

    h = hash_reassoc({}, :foo) do |value|
      refute value
      true
    end
    assert_equal({foo: true}, h)
    assert h.frozen?

    h = hash_reassoc({foo: 1}.freeze, :foo) do |value|
      assert_equal 1, value
      2
    end
    assert_equal({foo: 2}, h)
    assert h.frozen?

    h = hash_reassoc({foo: "bar".freeze}.freeze, :foo) do |value|
      assert_equal "bar", value
      refute value.frozen?
      "baz"
    end
    assert_equal({foo: "baz"}, h)
    assert h.frozen?
    assert h[:foo].frozen?

    h = hash_reassoc({foo: "bar".freeze}.freeze, :foo) do |value|
      assert_equal "bar", value
      refute value.frozen?
      value.sub!("r", "z")
    end
    assert_equal({foo: "baz"}, h)
    assert h.frozen?
    assert h[:foo].frozen?

    h = hash_reassoc({foo: {bar: "baz".freeze}.freeze}.freeze, :foo, :bar) do |value|
      assert_equal "baz", value
      refute value.frozen?
      "biz"
    end
    assert_equal({foo: {bar: "biz"}}, h)
    assert h.frozen?
    assert h[:foo].frozen?
    assert h[:foo][:bar].frozen?

    h = hash_reassoc({foo: {bar: {baz: "biz".freeze}.freeze}.freeze}.freeze, :foo, :bar, :baz) do |value|
      assert_equal "biz", value
      refute value.frozen?
      "foo"
    end
    assert_equal({foo: {bar: {baz: "foo"}}}, h)
    assert h.frozen?
    assert h[:foo].frozen?
    assert h[:foo][:bar].frozen?
    assert h[:foo][:bar][:baz].frozen?
  end

  def test_string_ends_with_semicolon
    assert string_end_with_semicolon?("var foo;")
    refute string_end_with_semicolon?("var foo")

    assert string_end_with_semicolon?("var foo;\n")
    refute string_end_with_semicolon?("var foo\n")

    assert string_end_with_semicolon?("var foo;\n\n")
    refute string_end_with_semicolon?("var foo\n\n")

    assert string_end_with_semicolon?("  var foo;\n  \n")
    refute string_end_with_semicolon?("  var foo\n  \n")

    assert string_end_with_semicolon?("\tvar foo;\n\t\n")
    refute string_end_with_semicolon?("\tvar foo\n\t\n")

    assert string_end_with_semicolon?("var foo\n;\n")
    refute string_end_with_semicolon?("var foo\n\n")
  end

  def test_concat_javascript_sources
    assert_equal "var foo;\n", apply_concat_javascript_sources("".freeze, "var foo;\n".freeze)
    assert_equal "\nvar foo;\n", apply_concat_javascript_sources("\n".freeze, "var foo;\n".freeze)
    assert_equal " \nvar foo;\n", apply_concat_javascript_sources(" ".freeze, "var foo;\n".freeze)

    assert_equal "var foo;\nvar bar;\n", apply_concat_javascript_sources("var foo;\n".freeze, "var bar;\n".freeze)
    assert_equal "var foo;\nvar bar;\n", apply_concat_javascript_sources("var foo".freeze, "var bar".freeze)
    assert_equal "var foo;\nvar bar;\n", apply_concat_javascript_sources("var foo;".freeze, "var bar;".freeze)
    assert_equal "var foo;\nvar bar;\n", apply_concat_javascript_sources("var foo".freeze, "var bar;".freeze)
  end

  def apply_concat_javascript_sources(*args)
    args.reduce(String.new(""), &method(:concat_javascript_sources))
  end


  def test_post_order_depth_first_search
    m = []
    m[11] = [4, 5, 10]
    m[4]  = [2, 3]
    m[10] = [8, 9]
    m[2]  = [0, 1]
    m[8]  = [6, 7]

    assert_equal Set.new(0..11), dfs(11) { |n| m[n] }

    m = []
    m[11] = [4, 5, 10]
    m[4]  = [2, 3]
    m[3]  = [1]
    m[5]  = [1, 2]
    m[10] = [8, 9]
    m[2]  = [0, 1]
    m[8]  = [6, 7]
    m[6]  = [5]

    assert_equal Set.new(0..11), dfs(11) { |n| m[n] }
  end

  def test_post_order_depth_first_find_all_paths
    m = []
    m[0] = [1]
    m[1] = [2]
    m[2] = [3]
    m[3] = [4, 5]
    m[4] = [1]

    assert_equal [
      [0, 1],
      [0, 1, 2],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4],
      [0, 1, 2, 3, 5]
    ], dfs_paths([0]) { |n| m[n] }

    assert_equal [
      [1, 2],
      [1, 2, 3],
      [1, 2, 3, 4],
      [1, 2, 3, 5]
    ], dfs_paths([1]) { |n| m[n] }

    assert_equal [], dfs_paths([5]) { |n| m[n] }
  end

  module Functions
    module InstanceMethods
      def bar
        2
      end
    end
    include InstanceMethods

    def foo
      1
    end
  end

  module ScopedFunctions
    def foo
      7
    end

    def bar
      8
    end

    def baz
      9
    end
  end

  module OtherScopedFunctions
    def bar
      3
    end

    def baz
      4
    end
  end

  class Context
    include Functions
  end

  def test_module_include
    context = Context.new

    assert context.respond_to?(:foo)
    assert context.respond_to?(:bar)
    refute context.respond_to?(:baz)

    assert_equal 1, context.foo
    assert_equal 2, context.bar

    module_include(Functions, ScopedFunctions) do
      assert context.respond_to?(:foo)
      assert context.respond_to?(:bar)
      assert context.respond_to?(:baz)

      assert_equal 7, context.foo
      assert_equal 8, context.bar
      assert_equal 9, context.baz
    end

    assert context.respond_to?(:foo)
    assert context.respond_to?(:bar)
    refute context.respond_to?(:baz)

    assert_equal 1, context.foo
    assert_equal 2, context.bar

    module_include(Functions, OtherScopedFunctions) do
      assert context.respond_to?(:foo)
      assert context.respond_to?(:bar)
      assert context.respond_to?(:baz)

      assert_equal 1, context.foo
      assert_equal 3, context.bar
      assert_equal 4, context.baz
    end

    assert context.respond_to?(:foo)
    assert context.respond_to?(:bar)
    refute context.respond_to?(:baz)

    assert_equal 1, context.foo
    assert_equal 2, context.bar
  end
end
