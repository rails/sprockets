require 'sprockets_test'

class TestCaching < Sprockets::TestCase
  def setup
    reset
  end

  def reset
    @cache = {}

    @env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end

    @env2 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end
  end

  test "same environment instance cache objects are equal" do
    env = @env1

    asset1 = env['gallery.js']
    asset2 = env['gallery.js']

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
  end

  test "same cached instance cache objects are equal" do
    cached = @env1.cached

    asset1 = cached['gallery.js']
    asset2 = cached['gallery.js']

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
  end

  test "same environment instance is cached at logical and expanded path" do
    env = @env1

    asset1 = env['gallery.js']
    asset2 = env[asset1.filename]

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
  end

  test "same cached instance is cached at logical and expanded path" do
    cached = @env1.cached

    asset1 = cached['gallery.js']
    asset2 = cached[asset1.filename]

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
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

  test "keys are different if environment digest changes" do
    @env1['gallery.js']
    old_keys = @cache.keys.sort

    @cache.clear
    @env2.version = '2.0'

    @env2['gallery.js']
    new_keys = @cache.keys.sort

    refute_equal old_keys, new_keys
  end

  class MockProcessor
    attr_reader :cache_key

    def initialize(cache_key)
      @cache_key = cache_key
    end

    def call(input)
    end
  end

  test "asset ids are different if preprocessor is added" do
    assert asset1 = @env1['gallery.js']

    @env2.register_preprocessor 'application/javascript', MockProcessor.new('1.0')
    assert asset2 = @env2['gallery.js']

    refute_equal asset1.id, asset2.id
  end

  test "asset ids are different if postprocessor is added" do
    assert asset1 = @env1['gallery.js']

    @env2.register_postprocessor 'application/javascript', MockProcessor.new('1.0')
    assert asset2 = @env2['gallery.js']

    refute_equal asset1.id, asset2.id
  end

  test "asset ids are different if bundle processor is added" do
    assert asset1 = @env1['gallery.js']

    @env2.register_bundle_processor 'application/javascript', MockProcessor.new('1.0')
    assert asset2 = @env2['gallery.js']

    refute_equal asset1.id, asset2.id
  end

  test "asset ids are different if processor cache key changes" do
    @env1.register_preprocessor 'application/javascript', MockProcessor.new('1.0')
    assert asset1 = @env1['gallery.js']

    @env2.register_preprocessor 'application/javascript', MockProcessor.new('2.0')
    assert asset2 = @env2['gallery.js']

    refute_equal asset1.id, asset2.id
  end

  test "unknown cache keys are ignored" do
    @env1.register_dependency_resolver 'foo-version' do |env|
      1
    end
    @env1.depend_on 'foo-version'

    assert asset1 = @env1['gallery.js']
    assert asset1.metadata[:dependencies].include?('foo-version')

    assert asset2 = @env2['gallery.js']
    refute asset2.metadata[:dependencies].include?('foo-version')

    refute_equal asset1.id, asset2.id
  end

  test "assets from different load paths are not equal" do
    # Normalize test fixture mtimes
    mtime = File.stat(fixture_path("default/app/main.js")).mtime.to_i
    File.utime(mtime, mtime, fixture_path("default/vendor/gems/jquery-2-0/jquery.js"))
    File.utime(mtime, mtime, fixture_path("default/vendor/gems/jquery-1-9/jquery.js"))

    env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor/gems/jquery-1-9")
      env.cache = @cache
    end

    env2 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor/gems/jquery-2-0")
      env.cache = @cache
    end

    refute_equal env1.find_asset("main.js"), env2.find_asset("main.js")
  end

  test "stale cached asset isn't loaded if file is remove" do
    filename = fixture_path("default/tmp.js")

    sandbox filename do
      File.open(filename, 'w') { |f| f.write "foo;\n" }
      assert_equal "foo;\n", @env1["tmp.js"].to_s

      File.unlink(filename)
      assert_nil @env2["tmp.js"]
    end
  end

  test "stale cached asset isn't loaded if dependency is changed and removed" do
    foo = fixture_path("default/foo-tmp.js")
    bar = fixture_path("default/bar-tmp.js")

    sandbox foo, bar do
      File.open(foo, 'w') { |f| f.write "//= require bar-tmp\nfoo;\n" }
      File.open(bar, 'w') { |f| f.write "bar;\n" }
      assert_equal "bar;\nfoo;\n", @env1["foo-tmp.js"].to_s
      assert_equal "bar;\n", @env1["bar-tmp.js"].to_s

      # File.open(foo, 'w') { |f| f.write "foo;\n" }
      File.unlink(bar)
      assert_nil @env2["bar-tmp.js"]
      assert_raises Sprockets::FileNotFound do
        @env1["foo-tmp.js"].to_s
      end
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

    assert_raises Sprockets::FileNotFound do
      env2["main.js"].to_s
    end
  end

  test "add/remove file to shadow vendor" do
    @env = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor")
      env.cache = @cache
    end

    patched_jquery = fixture_path('default/app/jquery.js')

    sandbox patched_jquery do
      File.utime(1421000000, 1422000000, File.dirname(patched_jquery))

      asset = @env["jquery.js"]
      assert_equal fixture_path('default/vendor/jquery.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s

      asset = @env["main.js"]
      assert_equal fixture_path('default/app/main.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s

      write(patched_jquery, "jQueryFixed;\n", 1422000010)

      asset = @env["main.js"]
      assert_equal fixture_path('default/app/main.js'), asset.filename
      assert_equal "jQueryFixed;\n", asset.to_s

      asset = @env["jquery.js"]
      assert_equal fixture_path('default/app/jquery.js'), asset.filename
      assert_equal "jQueryFixed;\n", asset.to_s

      File.unlink(patched_jquery)
      File.utime(1421000020, 1422000020, File.dirname(patched_jquery))

      asset = @env["jquery.js"]
      assert_equal fixture_path('default/vendor/jquery.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s

      asset = @env["main.js"]
      assert_equal fixture_path('default/app/main.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s
    end
  end

  test "add/remove index file to shadow vendor" do
    @env = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor")
      env.cache = @cache
    end

    patched_jquery = fixture_path('default/app/jquery/index.js')

    sandbox File.dirname(patched_jquery), patched_jquery do
      File.utime(1423000000, 1423000000, File.dirname(File.dirname(patched_jquery)))

      asset = @env["jquery.js"]
      assert_equal fixture_path('default/vendor/jquery.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s

      asset = @env["main.js"]
      assert_equal fixture_path('default/app/main.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s

      FileUtils.mkdir(File.dirname(patched_jquery))
      write(patched_jquery, "jQueryFixed;\n", 1423000010)

      asset = @env["main.js"]
      assert_equal fixture_path('default/app/main.js'), asset.filename
      assert_equal "jQueryFixed;\n", asset.to_s

      asset = @env["jquery.js"]
      assert_equal fixture_path('default/app/jquery/index.js'), asset.filename
      assert_equal "jQueryFixed;\n", asset.to_s

      File.unlink(patched_jquery)
      File.utime(1423000020, 1423000020, File.dirname(patched_jquery))

      asset = @env["jquery.js"]
      assert_equal fixture_path('default/vendor/jquery.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s

      asset = @env["main.js"]
      assert_equal fixture_path('default/app/main.js'), asset.filename
      assert_equal "jQuery;\n", asset.to_s
    end
  end

  test "seperate cache for dependencies under a different load path" do
    env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor/gems/jquery-1-9")
      env.cache = @cache
    end

    env2 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path("app")
      env.append_path("vendor/gems/jquery-2-0")
      env.cache = @cache
    end

    assert main = env1.find_asset("main.js")
    assert_equal "var jQuery;\n", main.to_s
    assert_equal fixture_path('default/app/main.js'), main.filename
    assert_equal main, env1.load(main.uri)
    assert_equal main, env1.find_asset("main.js")

    assert main = env2.find_asset("main.js")
    assert_equal "var jQuery;\n", main.to_s
    assert_equal fixture_path('default/app/main.js'), main.filename
    assert_equal main, env2.load(main.uri)
    assert_equal main, env2.find_asset("main.js")
  end

  test "environment cache resolver evaluated on load" do
    env = @env1
    assert asset1 = env['rand.js']
    assert asset2 = env['rand.js']
    refute_equal asset1.id, asset2.id
  end

  test "cached environment cache resolver evaluated onced" do
    env = @env1.cached
    assert asset1 = env['rand.js']
    assert asset2 = env['rand.js']
    assert_equal asset1.id, asset2.id
  end
end

require 'tmpdir'

class TestFileStoreCaching < Sprockets::TestCase
  def setup
    @cache_dir = File.join(Dir::tmpdir, 'sprockets')
    @cache     = Sprockets::Cache::FileStore.new(@cache_dir)
  end

  def teardown
    FileUtils.remove_entry(@cache_dir)
  end

  test "shared cache objects are eql" do
    @env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end

    @env2 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end

    asset1 = @env1['gallery.js']
    asset2 = @env2['gallery.js']

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
    assert !asset1.equal?(asset2)
  end

   test "no absolute paths are retuned from cache using sass" do
    env1 = Sprockets::Environment.new(fixture_path('sass')) do |env|
      env.append_path(".")
      env.cache = @cache
    end

    asset1 = silence_warnings do
      env1['variables.scss']
    end

    Dir.mktmpdir do |dir|
      env2 = Sprockets::Environment.new(dir) do |env|
        env.append_path(dir)
        env.cache = @cache
      end

      FileUtils.cp_r(env1.root + "/.", env2.root)

      asset2 = silence_warnings do
        env2['variables.scss']
      end

      assert asset1.metadata[:sass_dependencies]
      assert asset2.metadata[:sass_dependencies]

      assert_equal asset1.digest_path,              asset2.digest_path
      assert_equal asset1.source,                   asset2.source
      assert_equal asset1.hexdigest,                asset2.hexdigest

      # Absolute paths should be different
      refute_equal asset1.metadata[:sass_dependencies],  asset2.metadata[:sass_dependencies]
    end
  end

  test "history cache is not polluted" do
    dependency_file = File.join(fixture_path('asset'), "dependencies", "a.js")
    env1 = Sprockets::Environment.new(fixture_path('asset')) do |env|
      env.append_path(".")
      env.cache = @cache
    end
    env1['required_assets.js']

    sandbox dependency_file do
      write(dependency_file, "var aa = 2;")
      env1['required_assets.js']

      # We must use private APIs to test this behavior
      # https://github.com/rails/sprockets/pull/141
      cache_entries = @cache.send(:find_caches).map do |file, _|
        key    = file.gsub(/\.cache\z/, ''.freeze).split(@cache_dir).last
        result = @cache.get(key)

        if result.is_a?(Array)
          result if result.first.is_a?(Set)
        else
          nil
        end
      end.compact

      assert cache_entries.any?

      cache_entries.each do |sets|
        sets.each do |set|
          refute set.any? {|uri| uri.include?(env1.root) }, "Expected entry in cache to not include absolute paths but did: #{set.inspect}"
        end
      end
    end
  end

  test "no absolute paths are retuned from cache" do
    env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end
    asset1 = env1['schneems.js']

    Dir.mktmpdir do |dir|
      env2 = Sprockets::Environment.new(dir) do |env|
        env.append_path(dir)
        env.cache = @cache
      end

      FileUtils.cp_r(env1.root + "/.", env2.root)

      asset2 = env2['schneems.js']

      assert asset1
      assert asset2

      assert_equal asset1.digest_path,              asset2.digest_path
      assert_equal asset1.source,                   asset2.source
      assert_equal asset1.hexdigest,                asset2.hexdigest

      # Absolute paths should be different
      refute_equal asset1.uri,                      asset2.uri
      refute_equal asset1.filename,                 asset2.filename
      refute_equal asset1.included,                 asset2.included
      refute_equal asset1.to_hash[:load_path],      asset2.to_hash[:load_path]
      refute_equal asset1.metadata[:dependencies],  asset2.metadata[:dependencies]
      refute_equal asset1.metadata[:links],         asset2.metadata[:links]

      # The metadata[:stubbed] and metadata[:required] cannot be
      # observed directly, they are included in the `dependencies`.
      # We must use private APIs to test this behavior
      # https://github.com/rails/sprockets/issues/96#issuecomment-133097865
      cache_entries = @cache.send(:find_caches).map do |file, _|
        key    = file.gsub(/\.cache\z/, ''.freeze).split(@cache_dir).last
        result = @cache.get(key)
        result.is_a?(Hash) ? result : nil
      end.compact

      required = cache_entries.map do |asset|
        asset[:metadata][:required] if asset[:metadata]
      end.compact

      required.each do |set|
        refute set.any? {|uri| uri.include?(env1.root) || uri.include?(env2.root)}, "Expected 'required' entry in cache to not include absolute paths but did: #{set.inspect}"
      end

      stubbed = cache_entries.map do |asset|
        asset[:metadata][:stubbed] if asset[:metadata]
      end.compact

      stubbed.each do |set|
        refute set.any? {|uri| uri.include?(env1.root) || uri.include?(env2.root)}, "Expected 'stubbed' entry in cache to not include absolute paths but did: #{set.inspect}"
      end
    end
  end
end
