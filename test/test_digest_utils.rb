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
    assert_equal "94ee40cca7c2c6d2a134033d2f5a31c488cad5d3dcc61a3dbb5e2a858635874b", hexdigest("foo".encoding)

    assert_raises(TypeError) do
      hexdigest(Object.new)
    end
  end

  test "detect digest class" do
    md5    = Digest::MD5.new.digest
    sha1   = Digest::SHA1.new.digest
    sha256 = Digest::SHA256.new.digest
    sha512 = Digest::SHA512.new.digest

    refute detect_digest_class("0000")
    assert_equal Digest::MD5, detect_digest_class(md5)
    assert_equal Digest::SHA1, detect_digest_class(sha1)
    assert_equal Digest::SHA256, detect_digest_class(sha256)
    assert_equal Digest::SHA512, detect_digest_class(sha512)
  end

  test "integrity uri" do
    sha256 = Digest::SHA256.new.update("alert(1)")
    sha512 = Digest::SHA512.new.update("alert(1)")

    assert_equal "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI",
      integrity_uri(sha256)
    assert_equal "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI",
      integrity_uri(sha256.digest)

    assert_equal "ni:///sha-512;-uuYUxxe7oWIShQrWEmMn_fixz_rxDP4qcAZddXLDM3nN8_tpk1ZC2jXQk6N-mXE65jwfzNVUJL_qjA3y9KbuQ",
      integrity_uri(sha512)
    assert_equal "ni:///sha-512;-uuYUxxe7oWIShQrWEmMn_fixz_rxDP4qcAZddXLDM3nN8_tpk1ZC2jXQk6N-mXE65jwfzNVUJL_qjA3y9KbuQ",
      integrity_uri(sha512.digest)

    assert_equal "ni:///sha-256;bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI?ct=application/javascript",
      integrity_uri(sha256, "application/javascript")
  end
end
