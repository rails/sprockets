require 'matrix'
require 'sprockets_test'
require 'sprockets/utils'

class TestUtils < Sprockets::TestCase
  include Sprockets::Utils

  test "integrity_uri properly formats the named information URI" do
    expected = "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI"
    assert_equal expected, integrity_uri("alert(1)")
  end

  test "integrity_uri adds an encoded content-type if given one" do
    expected = "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI?ct=application%2Fjavascript"
    assert_equal expected, integrity_uri("alert(1)", "application/javascript")
  end

  test "string ends with semicolon" do
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

  test "concat javascript sources" do
    assert_equal "var foo;\nvar bar;\n", concat_javascript_sources("var foo;\n", "var bar;\n")
    assert_equal "var foo;\nvar bar", concat_javascript_sources("var foo", "var bar")
  end

  test "hexdigest" do
    assert_equal "15e1d872b31958c396eaac1d61b9e46aa2f5531f", hexdigest(nil)
    assert_equal "a88ea7cfcdafcd734a5e64234ba924227207df8c", hexdigest(true)
    assert_equal "0d9c2b81e82b07d10af56e40a76d70f4b979549b", hexdigest(false)
    assert_equal "58d7702df212c54f0a1f1f51b59f5ae988232ed8", hexdigest(42)
    assert_equal "fb993f056be461ce93d6a846692c9fdfceb50b21", hexdigest("foo")
    assert_equal "311a5592f7f7decd9b4b19d1350207a415c00608", hexdigest(:foo)
    assert_equal "107004472b7ba4e5e31f3082ee1fb5a1239eec61", hexdigest([])
    assert_equal "963e559076890aca4467f5b6abad3423808d3d17", hexdigest(["foo"])
    assert_equal "627e644e75d24c60d2128f6be4a7b3156cc7cd65", hexdigest({"foo" => "bar"})
    assert_equal "db5a9b24bbeecffcf6e0a289182a21d0d6013090", hexdigest({"foo" => "baz"})
    assert_equal "422444d146220ad542c4a89409f9bb30dcb3702b", hexdigest([[:foo, 1]])
    assert_equal "f7fcddffb6d8e5c089538f5d8ba32697df3bdc4f", hexdigest([{:foo => 1}])

    assert_raises(TypeError) do
      hexdigest(Object.new)
    end
  end

  test "post-order depth-first search" do
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

  test "module include" do
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
