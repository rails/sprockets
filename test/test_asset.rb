require "sprockets_test"

class AssetTest < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path('asset')
  end

  test "requiring the same file multiple times has no effect" do
    assert_equal source_file("project.js").source, asset("multiple.js").source
  end

  test "requiring a file of a different format raises an exception" do
    assert_raise Sprockets::ContentTypeMismatch do
      asset("mismatch.js")
    end
  end

  test "dependencies appear in the source before files that required them" do
    assert_match(/Project.+Users.+focus/m, asset("application.js").source)
  end

  test "processing a source file with no engine extensions" do
    assert_equal source_file("users.js").source, asset("noengine.js").source
  end

  test "processing a source file with one engine extension" do
    assert_equal source_file("users.js").source, asset("oneengine.js").source
  end

  test "processing a source file with multiple engine extensions" do
    assert_equal source_file("users.js").source, asset("multipleengine.js").source
  end

  test "included dependencies are inserted after the header of the dependent file" do
    assert_equal "# My Application" + source_file("project.js").source + "\nhello()\n",
      asset("included_header.js").source
  end

  test "asset mtime is the latest mtime of all processed sources" do
    mtime = Time.now
    path  = source_file("project.js").path
    File.utime(mtime, mtime, path)
    assert_equal File.mtime(path), asset("application.js").mtime
  end

  test "asset inherits the format extension and content type of the original file" do
  end

  def asset(logical_path)
    Sprockets::Asset.require(@env, source_file(logical_path))
  end

  def source_file(logical_path)
    @env.find_source_file(logical_path)
  end
end
