require 'minitest/autorun'
require 'sprockets/utils'

class TestUtils < MiniTest::Test
  include Sprockets::Utils

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
    assert_equal "var foo;\nvar bar;\n", concat_javascript_sources("var foo;\n", "var bar;\n")
    assert_equal "var foo;\nvar bar", concat_javascript_sources("var foo", "var bar")
  end

  def test_post_order_depth_first_search
    m = Array.new
    m[11] = [4, 5, 10]
    m[4]  = [2, 3]
    m[10] = [8, 9]
    m[2]  = [0, 1]
    m[8]  = [6, 7]

    assert_equal Set.new(0..11), dfs(11) { |n| m[n] }

    m = Array.new
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
