require 'sprockets_test'

class TestCaching < Sprockets::TestCase
  def setup
    @cache = {}

    @env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end

    @env2 = Sprockets::Environment.new(fixture_path('symlink')) do |env|
      env.append_path(".")
      env.cache = @cache
    end
  end

  test "environment digests are the same for different roots" do
    assert_equal @env1.digest, @env2.digest
  end

  test "same environment instance cache objects are equal" do
    env = @env1

    asset1 = env['gallery.js']
    asset2 = env['gallery.js']

    assert asset1
    assert asset2

    assert asset1.equal?(asset2)
    assert asset2.equal?(asset1)
  end

  test "same index instance cache objects are equal" do
    index = @env1.index

    asset1 = index['gallery.js']
    asset2 = index['gallery.js']

    assert asset1
    assert asset2

    assert asset1.equal?(asset2)
    assert asset2.equal?(asset1)
  end

  test "shared cache objects are eql" do
    asset1 = @env1['gallery.js']
    asset2 = @env2['gallery.js']

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
    assert !asset1.equal?(asset2)
  end

  test "proccessed and bundled assets are cached separately" do
    env = @env1
    assert_kind_of Sprockets::ProcessedAsset, env['gallery.js', :bundle => false]
    assert_kind_of Sprockets::BundledAsset,   env['gallery.js', :bundle => true]
    assert_kind_of Sprockets::ProcessedAsset, env['gallery.js', :bundle => false]
    assert_kind_of Sprockets::BundledAsset,   env['gallery.js', :bundle => true]
  end

  test "proccessed and bundled assets are cached separately on index" do
    index = @env1.index
    assert_kind_of Sprockets::ProcessedAsset, index['gallery.js', :bundle => false]
    assert_kind_of Sprockets::BundledAsset,   index['gallery.js', :bundle => true]
    assert_kind_of Sprockets::ProcessedAsset, index['gallery.js', :bundle => false]
    assert_kind_of Sprockets::BundledAsset,   index['gallery.js', :bundle => true]
  end

  test "stale cached asset isn't loaded if file is remove" do
    filename = fixture_path("default/tmp.js")

    sandbox filename do
      File.open(filename, 'w') { |f| f.puts "foo;" }
      assert_equal "foo;\n", @env1["tmp.js"].to_s

      File.unlink(filename)
      assert_nil @env2["tmp.js"]
    end
  end

  test "stale cached asset isn't loaded if depedency is changed and removed" do
    foo = fixture_path("default/foo-tmp.js")
    bar = fixture_path("default/bar-tmp.js")

    sandbox foo, bar do
      File.open(foo, 'w') { |f| f.puts "//= require bar-tmp\nfoo;" }
      File.open(bar, 'w') { |f| f.puts "bar;" }
      assert_equal "bar;\nfoo;\n", @env1["foo-tmp.js"].to_s
      assert_equal "bar;\n", @env1["bar-tmp.js"].to_s

      File.open(foo, 'w') { |f| f.puts "foo;" }
      File.unlink(bar)
      assert_equal "foo;\n", @env1["foo-tmp.js"].to_s
      assert_nil @env2["bar-tmp.js"]
    end
  end
end
