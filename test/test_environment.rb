require 'sprockets_test'

class TestEnvironment < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
    @env.paths << fixture_path('default')
    @env.static_root = fixture_path('public')
  end

  test "working directory is the default root" do
    assert_equal Dir.pwd, @env.root
  end

  test "resolve in environment" do
    assert_equal fixture_path('default/gallery.js'),
      @env.resolve("gallery.js").path
  end

  test "resolve compiled asset in static root" do
    assert_equal fixture_path('public/compiled.js'),
      @env.resolve("compiled.js").path
  end

  test "resolve compiled asset with filename digest in static root" do
    assert_equal fixture_path('public/compiled-digest-0aa2105d29558f3eb790d411d7d8fb66.js'),
      @env.resolve("compiled-digest.js").path
  end

  test "missing file raises an exception" do
    assert_raises(Sprockets::FileNotFound) do
      @env.resolve("null")
    end
  end

  test "build static asset" do
    assert_equal "Hello world\n", @env.build_asset("hello.txt").to_s
  end

  test "build asset returns nil if file is missing" do
    assert_nil @env.build_asset("null")
  end

  test "find concatenated asset in environment" do
    assert_equal "var Gallery = {};\n", @env["gallery.js"].to_s
  end

  test "find static asset in environment" do
    assert_equal "Hello world\n", @env["hello.txt"].to_s
  end

  test "find compiled asset in static root" do
    assert_equal "(function() {\n  application.boot();\n})();\n",
      @env["compiled.js"].to_s
  end

  test "find compiled asset in static root is StaticAsset" do
    assert_equal Sprockets::StaticAsset, @env["compiled.js"].class
  end

  test "find compiled asset with filename digest in static root" do
    assert_equal "(function() {\n  application.boot();\n})();\n",
      @env["compiled-digest.js"].to_s
  end

  test "find asset with digest" do
    assert_equal "Hello world\n",
      @env["hello.txt", "f0ef7081e1539ac00ef5b761b4fb01b3"].to_s
  end

  test "find asset with blank digest" do
    assert_equal "Hello world\n",
      @env["hello.txt", ""].to_s
  end

  test "find asset with invalid digest" do
    assert_nil @env["hello.txt", "invalid"]
  end

  test "missing asset returns nil" do
    assert_equal nil, @env["missing.js"]
  end

  test "asset with missing requires raises an exception" do
    assert_raises Sprockets::FileNotFound do
      @env["missing_require.js"]
    end
  end

  test "lookup asset digest" do
    assert_equal "f1598cfbaf2a26f20367e4046957f6e0",
      @env["gallery.js"].digest
  end
end
