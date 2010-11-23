require "sprockets_test"

class AssetTest < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path('asset')
  end

  test "requiring the same file multiple times has no effect" do
    @asset = Sprockets::Asset.require(@env, source_file("multiple.js"))
    assert_equal source_file("project.js").source, @asset.source
  end

  test "requiring a file of a different format raises an exception" do
    assert_raise Sprockets::ContentTypeMismatch do
      Sprockets::Asset.require(@env, source_file("mismatch.js"))
    end
  end

  test "dependencies appear in the source before files that required them" do
  end

  test "processing a source file with no engine extensions" do
  end

  test "processing a source file with one engine extension" do
  end

  test "processing a source file with multiple engine extensions" do
  end

  test "included dependencies are inserted after the header of the dependent file" do
  end

  test "asset mtime is the latest mtime of all processed sources" do
  end

  test "asset inherits the format extension and content type of the original file" do
  end

  def source_file(logical_path)
    @env.find_source_file(logical_path)
  end
end
