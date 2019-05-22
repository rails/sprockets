# frozen_string_literal: true
require 'minitest/autorun'
require 'sprockets/manifest_utils'
require 'logger'

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

  end

  def test_warn_on_two
    root = File.expand_path("../fixtures/manifest_utils", __FILE__)

    assert_match MANIFEST_RE, File.basename(find_directory_manifest(root))

    r, w = IO.pipe
    logger = Logger.new(w)
    # finds the first one alphabetically
    assert_equal "#{root}/with_two_manifests/.sprockets-manifest-00000000000000000000000000000000.json",
      find_directory_manifest("#{root}/with_two_manifests", logger)
    output = r.gets

    assert_match(/W, \[[^\]]+\]  WARN -- : Found multiple manifests: .+ Choosing the first alphabetically: \.sprockets-manifest-00000000000000000000000000000000\.json/, output)
  end
end
