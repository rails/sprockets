require 'sprockets_test'
require 'sprockets/utils'

class TestUtils < Sprockets::TestCase
  include Sprockets::Utils

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

  def find(arg)
    prevent_circular_calls(arg) do
      if arg.is_a?(Integer)
        if arg > 0
          find(arg - 1)
        else
          find(10)
        end
      elsif arg == :circle
        find(arg)
      else
        arg
      end
    end
  end

  test "prevent circular calls" do
    assert_equal :foo, find(:foo)

    assert_raises(Sprockets::CircularDependencyError) do
      find(:circle)
    end

    assert_raises(Sprockets::CircularDependencyError) do
      find(9)
    end
  end
end
