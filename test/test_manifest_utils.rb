require 'minitest/autorun'
require 'sprockets/manifest_utils'

class TestManifestUtils < MiniTest::Test
  include Sprockets::ManifestUtils

  def test_generate_manifest_path
    assert_match(MANIFEST_RE, generate_manifest_path)
  end

  def test_find_directory_manifest
    root = File.expand_path("../fixtures/manifest_utils", __FILE__)

    assert_match MANIFEST_RE, File.basename(find_directory_manifest(root))

    assert_equal "#{root}/default/.sprockets-manifest-f4bf345974645583d284686ddfb7625e.json",
      find_directory_manifest("#{root}/default")

    assert_equal "#{root}/legacy/manifest-02f33520c330d408567423cefa7a03ba.json",
      find_directory_manifest("#{root}/legacy")

    assert_equal "#{root}/legacy2/manifest.json",
      find_directory_manifest("#{root}/legacy2")
  end
end
