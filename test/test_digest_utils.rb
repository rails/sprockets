require 'minitest/autorun'
require 'sprockets/digest_utils'

class TestDigestUtils < MiniTest::Test
  include Sprockets::DigestUtils

  def test_detect_digest_class
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

  def hexdigest(obj)
    pack_hexdigest(digest(obj))
  end

  def test_digest
    assert_equal "9bda381dac87b1c16b04f996abb623f43f1cdb89ce8be7dda3f67319dc440bc5", hexdigest(nil)
    assert_equal "92de503a8b413365fc38050c7dd4bacf28b0f705e744dacebcaa89f2032dcd67", hexdigest(true)
    assert_equal "bdfd64a7c8febcc3b0b8fb05d60c8e2a4cb6b8c081fcba20db1c9778e9beaf89", hexdigest(false)
    assert_equal "291e87109f89e59ad717aebe4ffc9657c700e74da45db789ecd19d6b797baee2", hexdigest(42)
    assert_equal "d1312b90a6258e9bda7d10e5e1ab1468d92786eca72a65b5ab077169e36bcb1e", hexdigest(2 ** 128)
    assert_equal "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae", hexdigest("foo")
    assert_equal "dea6712e86478d2ee22a35a8c5ac9627e7cbc5ce2407a7da7c645fea2434fe9b", hexdigest(:foo)
    assert_equal "f0cf39d0be3efbb6f86ac2404100ff7e055c17ded946a06808d66f89ca03a811", hexdigest([])
    assert_equal "ed98cc300019b22ca15e7cd5934028a79e7af4c75f7eeea810f43a3a4353a04d", hexdigest(["foo"])
    assert_equal "54edcfe382f4abaa9ebe93efa9977b05b786c9058496609797989b7fdf8208d4", hexdigest({"foo" => "bar"})
    assert_equal "62427aa539a0b78e90fd710dc0e15f2960771ba44214b5d41d4a93a8b2940a38", hexdigest({"foo" => "baz"})
    assert_equal "b6054efd9929004bdd0a1c09eb2d12961325396da749143def3e9a4050aa703e", hexdigest([[:foo, 1]])
    assert_equal "79a19ffe41ecebd5dc35e95363e0b4aa79b139a22bc650384df57eb09842f099", hexdigest([{:foo => 1}])
    assert_equal "94ee40cca7c2c6d2a134033d2f5a31c488cad5d3dcc61a3dbb5e2a858635874b", hexdigest("foo".force_encoding('UTF-8').encoding)

    assert_raises(TypeError) do
      digest(Object.new)
    end
  end

  def test_pack_hexdigest
    digest = Digest::SHA256.new.update("alert(1)")

    assert_equal "6e11c72f7cf6bc383152dd16ddd5903aba6bb1c99d6b6639a4bb0b838185fa92", digest.hexdigest
    assert_equal "6e11c72f7cf6bc383152dd16ddd5903aba6bb1c99d6b6639a4bb0b838185fa92", pack_hexdigest(digest.digest)
  end

  def test_unpack_hexdigest
    digest = Digest::SHA256.new.update("alert(1)")
    assert_equal digest.digest, unpack_hexdigest(digest.hexdigest)
  end

  def test_pack_base64_digest
    digest = Digest::SHA256.new.update("alert(1)")

    assert_equal "bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI=", digest.base64digest
    assert_equal "bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI=", pack_base64digest(digest.digest)
  end

  def test_pack_urlsafe_base64_digest
    digest = Digest::SHA256.new.update("alert(1)")

    assert_equal "bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF-pI", pack_urlsafe_base64digest(digest.digest)
  end

  def test_integrity_uri
    sha256 = Digest::SHA256.new.update("alert(1)")
    sha512 = Digest::SHA512.new.update("alert(1)")

    assert_equal "sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI=",
      integrity_uri(sha256)
    assert_equal "sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI=",
      integrity_uri(sha256.digest)

    assert_equal "sha512-+uuYUxxe7oWIShQrWEmMn/fixz/rxDP4qcAZddXLDM3nN8/tpk1ZC2jXQk6N+mXE65jwfzNVUJL/qjA3y9KbuQ==",
      integrity_uri(sha512)
    assert_equal "sha512-+uuYUxxe7oWIShQrWEmMn/fixz/rxDP4qcAZddXLDM3nN8/tpk1ZC2jXQk6N+mXE65jwfzNVUJL/qjA3y9KbuQ==",
      integrity_uri(sha512.digest)

    # echo -n "alert('Hello, world.');" | openssl dgst -sha256 -binary | openssl enc -base64 -A
    sha256 = Digest::SHA256.new.update("alert('Hello, world.');")
    assert_equal "sha256-qznLcsROx4GACP2dm0UCKCzCG+HiZ1guq6ZZDob/Tng=",
      integrity_uri(sha256)
  end

  def test_hexdigest_integrity_uri
    sha256 = Digest::SHA256.new.update("alert(1)").hexdigest
    sha512 = Digest::SHA512.new.update("alert(1)").hexdigest

    assert_equal "sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI=",
      hexdigest_integrity_uri(sha256)

    assert_equal "sha512-+uuYUxxe7oWIShQrWEmMn/fixz/rxDP4qcAZddXLDM3nN8/tpk1ZC2jXQk6N+mXE65jwfzNVUJL/qjA3y9KbuQ==",
      hexdigest_integrity_uri(sha512)
  end
end
