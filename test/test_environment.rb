require 'sprockets_test'

class TestEnvironment < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path('default')
  end

  test "working directory is the default root" do
    assert_equal Dir.pwd, @env.root
  end

  test "find source file in environment" do
    assert_equal fixture_path('default/gallery.js'),
      @env.find_source_file("gallery.js").path
  end

  test "missing source file raises an exception" do
    assert_raises(Sprockets::SourceFile::MissingError) do
      @env.find_source_file("null")
    end
  end

  test "find asset in environment" do
    assert_equal fixture_path('default/gallery.js'),
      @env.find_asset("gallery.js").source_paths.first
  end
end
