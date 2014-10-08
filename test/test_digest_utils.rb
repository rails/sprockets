require 'sprockets_test'
require 'sprockets/digest_utils'

class TestDigestUtils < Sprockets::TestCase
  include Sprockets::DigestUtils

  test "hexdigest" do
    assert_equal "9bda381dac87b1c16b04f996abb623f43f1cdb89ce8be7dda3f67319dc440bc5", hexdigest(nil)
    assert_equal "92de503a8b413365fc38050c7dd4bacf28b0f705e744dacebcaa89f2032dcd67", hexdigest(true)
    assert_equal "bdfd64a7c8febcc3b0b8fb05d60c8e2a4cb6b8c081fcba20db1c9778e9beaf89", hexdigest(false)
    assert_equal "0d4af38194cb7dc915a75b04926886f6753ffc5b4f54513adfc582fdf3642e8c", hexdigest(42)
    assert_equal "15020d93a6f635366cb20229cb3931c3651992dc6df85cddecc743fa11e48a66", hexdigest("foo")
    assert_equal "dea6712e86478d2ee22a35a8c5ac9627e7cbc5ce2407a7da7c645fea2434fe9b", hexdigest(:foo)
    assert_equal "f0cf39d0be3efbb6f86ac2404100ff7e055c17ded946a06808d66f89ca03a811", hexdigest([])
    assert_equal "e94fc8aee40dbc2a0d8882758da1b7fcf96bb77948de8c998bc1765a4c7648e0", hexdigest(["foo"])
    assert_equal "34e0b926073091afda216fad3147ce2923c1b6b5aeafbce810a85c3b7b6d4d41", hexdigest({"foo" => "bar"})
    assert_equal "28e62207146f413a3c7779609bda0b2607282b940a037059e4ccbf0f38112c56", hexdigest({"foo" => "baz"})
    assert_equal "905e6cc86eccb1849ae6c1e0bb01b96fedb3e341ad3d60f828e93e9b5e469a4f", hexdigest([[:foo, 1]])
    assert_equal "9500d3562922431a8ccce61bd510d341ca8d61cf6b6e5ae620e7b1598436ed73", hexdigest([{:foo => 1}])

    assert_raises(TypeError) do
      hexdigest(Object.new)
    end
  end

  test "integrity uri properly formats the named information URI" do
    digest = Digest::SHA256.digest("alert(1)")
    expected = "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI"
    assert_equal expected, integrity_uri(digest)
  end

  test "integrity uri adds an encoded content-type if given one" do
    digest = Digest::SHA256.digest("alert(1)")
    expected = "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI?ct=application/javascript"
    assert_equal expected, integrity_uri(digest, "application/javascript")
  end
end
