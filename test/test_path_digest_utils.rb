require 'minitest/autorun'
require 'sprockets/path_digest_utils'

class TestPathDigestUtils < MiniTest::Test
  include Sprockets::PathDigestUtils

  def test_file_stat_digest
    path = File.expand_path("../fixtures/default/hello.txt", __FILE__)
    assert_equal "81491ac958ab51a3bc7f34cae434cf00c49861402bf6c8961e8ee32afa7c4cf8",
      stat_digest(path, File.stat(path)).unpack("h*")[0]
    assert_equal "81491ac958ab51a3bc7f34cae434cf00c49861402bf6c8961e8ee32afa7c4cf8",
      file_digest(path).unpack("h*")[0]
  end

  def test_directory_stat_digest
    path = File.expand_path("../fixtures/default/app", __FILE__)
    assert_equal "8514e7f087b1666549d97352c8b80925de62e6e27b5a61c3dab780366e2b19a6",
      stat_digest(path, File.stat(path)).unpack("h*")[0]
    assert_equal "8514e7f087b1666549d97352c8b80925de62e6e27b5a61c3dab780366e2b19a6",
      file_digest(path).unpack("h*")[0]
  end

  def test_symlink_stat_digest
    skip "no symlinks available" unless File.symlink?(File.expand_path("../fixtures/default/symlink", __FILE__))

    path = File.expand_path("../fixtures/default/mobile", __FILE__)
    assert_equal "e571f54b8982049817ee30d0bf0dcf5dd8c09252b50696f7ccb44019c9229ccd",
      stat_digest(path, File.stat(path)).unpack("h*")[0]

    path = File.expand_path("../fixtures/default/symlink", __FILE__)
    assert_equal "e571f54b8982049817ee30d0bf0dcf5dd8c09252b50696f7ccb44019c9229ccd",
      stat_digest(path, File.stat(path)).unpack("h*")[0]
    assert_equal "e571f54b8982049817ee30d0bf0dcf5dd8c09252b50696f7ccb44019c9229ccd",
      file_digest(path).unpack("h*")[0]
  end

  def test_unix_device_stat_digest
    if File.exist?("/dev/stdin") && File.stat("/dev/stdin").chardev?
      assert_raises(TypeError) do
        stat_digest("/dev/stdin", File.stat("/dev/stdin"))
      end
      assert_raises(TypeError) do
        file_digest("/dev/stdin")
      end
    else
      skip "no unix device available"
    end
  end

  def test_missing_file_digest
    path = "./filedoesnotexist"
    refute File.exist?(path)
    refute file_digest(path)
  end

  def test_multiple_file_digests
    skip "no symlinks available" unless File.symlink?(File.expand_path("../fixtures/default/symlink", __FILE__))

    paths = []
    paths << File.expand_path("../fixtures/default/hello.txt", __FILE__)
    paths << File.expand_path("../fixtures/default/app", __FILE__)
    paths << File.expand_path("../fixtures/default/symlink", __FILE__)
    paths << "./filedoesnotexist"

    assert_equal "95f41ef27ae30ceaaa726f85b3298e1be4ff4bf5bf83deec0f760b50e3ffc09f",
      files_digest(paths).unpack("h*")[0]
  end
end
