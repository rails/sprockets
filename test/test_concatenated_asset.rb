require "sprockets_test"

class ConcatenatedAssetTest < Sprockets::TestCase
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
    asset = asset("project.js")
    assert_equal ".js", asset.format_extension
    assert_equal "application/javascript", asset.content_type
  end

  test "asset is a rack response body" do
    body = ""
    asset("project.js").each { |part| body += part }
    assert_equal asset("project.js").source, body
  end

  test "asset length is source length" do
    assert_equal 46, asset("project.js").length
  end

  test "asset md5" do
    assert_equal "35d470ef8621efa573dee227a4feaba3", asset("project.js").md5
  end

  test "asset etag" do
    assert_equal '"35d470ef8621efa573dee227a4feaba3"', asset("project.js").etag
  end

  test "asset is stale when one of its source files is modified" do
    asset = asset("application.js")
    assert !asset.stale?

    mtime = Time.now + 1
    File.utime(mtime, mtime, source_file("project.js").path)

    assert asset.stale?
  end

  def asset(logical_path)
    Sprockets::ConcatenatedAsset.new(@env, resolve(logical_path))
  end

  def resolve(logical_path)
    @env.resolve(logical_path)
  end

  def source_file(logical_path)
    Sprockets::SourceFile.new(resolve(logical_path))
  end
end
