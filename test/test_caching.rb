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

  test "shared cache objects are eql" do
    asset1 = @env1['gallery.js']
    asset2 = @env2['gallery.js']

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
    assert !asset1.equal?(asset2)
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

  test "stale cached asset isn't loaded if removed from path" do
    env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor")
      env.cache = @cache
    end

    env2 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.cache = @cache
    end

    assert_equal "jQuery;\n", env1["main.js"].to_s
    assert_equal "jQuery;\n", env1["jquery.js"].to_s
    assert env1["main.js"].fresh?

    assert_raises Sprockets::FileNotFound do
      env2["main.js"].to_s
    end
  end
end
