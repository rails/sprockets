require 'sprockets_test'

$file_stat_calls = nil
class << File
  alias_method :original_stat, :stat
  def stat(filename)
    if $file_stat_calls
      $file_stat_calls[filename.to_s] ||= []
      $file_stat_calls[filename.to_s] << caller
    end
    original_stat(filename)
  end
end

$dir_entires_calls = nil
class << Dir
  alias_method :original_entries, :entries
  def entries(dirname, *args)
    if $dir_entires_calls
      $dir_entires_calls[dirname.to_s] ||= []
      $dir_entires_calls[dirname.to_s] << caller
    end
    original_entries(dirname, *args)
  end
end

class TestPerformance < Sprockets::TestCase
  class Cache
    def initialize
      @cache = {}
    end

    def get(key)
      $cache_get_calls[key] ||= []
      $cache_get_calls[key] << caller
      @cache[key]
    end

    def set(key, value)
      $cache_set_calls[key] ||= []
      $cache_set_calls[key] << caller
      @cache[key] = value
    end
  end

  def setup
    @env = new_environment
    reset_stats!
  end

  def teardown
    $file_stat_calls = nil
    $dir_entires_calls = nil
    $processor_calls = nil
    $bundle_processor_calls = nil
    $cache_get_calls = nil
    $cache_set_calls = nil
  end

  test "simple file" do
    @env["gallery.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
  end

  test "cached simple file" do
    @env.cached["gallery.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
  end

  test "file with deps" do
    @env["mobile.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
  end

  test "cached file with deps" do
    @env.cached["mobile.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
  end

  test "loading from backend cache" do
    env1, env2 = new_environment, new_environment
    cache = Cache.new
    env1.cache = cache
    env2.cache = cache

    env1["mobile.js"]
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    reset_stats!

    env2["mobile.js"]
    assert_no_redundant_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
    assert_no_redundant_cache_get_calls
    assert_no_cache_set_calls
  end

  test "moving root of project after generation is still freaky fast" do
    env1 = new_environment
    env1.cache = Cache.new

    env1["mobile.js"]
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `cp -R #{File.join(fixture_path("default"), "*")} .`
        env2       = new_environment("./default")
        env2.cache = env1.cache

        reset_stats!

        env2["mobile.js"]
        assert_no_redundant_stat_calls
        assert_no_processor_calls
        assert_no_bundle_processor_calls
        assert_no_redundant_cache_get_calls
        assert_no_cache_set_calls
      end
    end
  end

  test "loading from instance cache" do
    env = @env.cached
    env["mobile.js"]
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls

    reset_stats!

    env["mobile.js"]
    assert_no_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
  end

  test "loading from cached with backend cache" do
    env1, env2 = new_environment, new_environment
    cache = Cache.new
    env1.cache = cache
    env2.cache = cache

    env1.cached["mobile.js"]
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    reset_stats!

    env2.cached["mobile.js"]
    assert_no_redundant_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
    assert_no_redundant_cache_get_calls
    assert_no_cache_set_calls
  end

  test "rollback version" do
    env = new_environment
    env.cache = Cache.new

    env.version = "1"
    assert asset = env["mobile.js"]
    id1 = asset.id
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    reset_stats!

    env.version = "2"
    assert asset = env["mobile.js"]
    id2 = asset.id
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    reset_stats!

    env.version = "1"
    assert asset = env["mobile.js"]
    assert_equal id1, asset.id
    assert_no_redundant_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
    assert_no_redundant_cache_get_calls
    assert_no_cache_set_calls

    reset_stats!

    env.version = "2"
    assert asset = env["mobile.js"]
    assert_equal id2, asset.id
    assert_no_redundant_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
    assert_no_redundant_cache_get_calls
    assert_no_cache_set_calls
  end

  test "rollback path change" do
    env = new_environment
    env.cache = Cache.new

    env.clear_paths
    env.append_path(fixture_path('default'))

    assert asset = env["mobile.js"]
    path1 = asset.id
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    reset_stats!
    env.clear_paths
    env.append_path(fixture_path('asset'))
    env.append_path(fixture_path('default'))

    assert asset = env["mobile.js"]
    path2 = asset.id
    assert_no_redundant_processor_calls
    assert_no_redundant_bundle_processor_calls
    assert_no_redundant_cache_set_calls

    reset_stats!
    env.clear_paths
    env.append_path(fixture_path('default'))

    assert asset = env["mobile.js"]
    assert_equal path1, asset.id
    assert_no_redundant_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
    assert_no_redundant_cache_get_calls
    assert_no_cache_set_calls

    reset_stats!
    env.clear_paths
    env.append_path(fixture_path('asset'))
    env.append_path(fixture_path('default'))

    assert asset = env["mobile.js"]
    assert_equal path2, asset.id
    assert_no_redundant_stat_calls
    assert_no_processor_calls
    assert_no_bundle_processor_calls
    assert_no_redundant_cache_get_calls
    assert_no_cache_set_calls
  end

  test "rollback file change" do
    env = new_environment
    env.cache = Cache.new

    filename = fixture_path("default/tmp.js")

    sandbox filename do
      write(filename, "a;", 1421000000)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "a;\n", asset.source
      ida = asset.id
      assert_no_redundant_processor_calls
      assert_no_redundant_bundle_processor_calls
      assert_no_redundant_cache_set_calls

      write(filename, "b;", 1421000001)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "b;\n", asset.source
      idb = asset.id
      assert_no_redundant_processor_calls
      assert_no_redundant_bundle_processor_calls
      assert_no_redundant_cache_set_calls

      write(filename, "a;", 1421000000)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "a;\n", asset.source
      assert_equal ida, asset.id
      assert_no_redundant_stat_calls
      assert_no_processor_calls
      assert_no_bundle_processor_calls
      assert_no_redundant_cache_get_calls
      assert_no_cache_set_calls

      write(filename, "b;", 1421000001)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "b;\n", asset.source
      assert_equal idb, asset.id
      assert_no_redundant_stat_calls
      assert_no_processor_calls
      assert_no_bundle_processor_calls
      assert_no_redundant_cache_get_calls
      assert_no_cache_set_calls
    end
  end

  test "rollback file dependency change" do
    env = new_environment
    env.cache = Cache.new

    main = fixture_path("default/tmp-main.js")
    dep  = fixture_path("default/tmp-dep.js")

    sandbox main, dep do
      write(main, "//= require ./tmp-dep", 1421000000)
      write(dep, "a;", 1421000000)
      reset_stats!

      assert asset = env["tmp-main.js"]
      assert_equal "a;\n", asset.source
      ida = asset.id
      assert_no_redundant_processor_calls
      assert_no_redundant_bundle_processor_calls
      assert_no_redundant_cache_set_calls

      write(dep, "b;", 1421000001)
      reset_stats!

      assert asset = env["tmp-main.js"]
      assert_equal "b;\n", asset.source
      idb = asset.id
      assert_no_redundant_processor_calls
      assert_no_redundant_bundle_processor_calls
      assert_no_redundant_cache_set_calls

      write(dep, "a;", 1421000000)
      reset_stats!

      assert asset = env["tmp-main.js"]
      assert_equal "a;\n", asset.source
      assert_equal ida, asset.id
      assert_no_redundant_stat_calls
      assert_no_processor_calls
      assert_no_bundle_processor_calls
      assert_no_redundant_cache_get_calls
      assert_no_cache_set_calls

      write(dep, "b;", 1421000001)
      reset_stats!

      assert asset = env["tmp-main.js"]
      assert_equal "b;\n", asset.source
      assert_equal idb, asset.id
      assert_no_redundant_stat_calls
      assert_no_processor_calls
      assert_no_bundle_processor_calls
      assert_no_redundant_cache_get_calls
      assert_no_cache_set_calls
    end
  end

  test "rollback file dependency add/remove" do
    env = new_environment
    env.cache = Cache.new

    main = fixture_path("default/tmp.js")
    deps = fixture_path("default/tmp")
    depa = fixture_path("default/tmp/a.js")
    depb = fixture_path("default/tmp/b.js")

    sandbox main, deps, depa, depb do
      FileUtils.mkdir_p(deps)
      write(main, "//= require_directory ./tmp", 1421000000)
      write(depa, "a;", 1421000000)
      File.utime(1421000000, 1421000000, deps)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "a;\n", asset.source
      ida = asset.id
      assert_no_redundant_processor_calls
      assert_no_redundant_bundle_processor_calls
      assert_no_redundant_cache_set_calls

      write(depb, "b;", 142100001)
      File.utime(1421000001, 1421000001, deps)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "a;\nb;\n", asset.source
      idab = asset.id
      assert_no_redundant_processor_calls
      assert_no_redundant_bundle_processor_calls
      assert_no_redundant_cache_set_calls

      FileUtils.rm(depb)
      File.utime(1421000000, 1421000000, deps)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "a;\n", asset.source
      assert_equal ida, asset.id
      assert_no_redundant_stat_calls
      assert_no_processor_calls
      assert_no_bundle_processor_calls
      assert_no_redundant_cache_get_calls
      assert_no_redundant_cache_set_calls

      write(depb, "b;", 142100001)
      File.utime(1421000001, 1421000001, deps)
      reset_stats!

      assert asset = env["tmp.js"]
      assert_equal "a;\nb;\n", asset.source
      assert_equal idab, asset.id
      assert_no_redundant_stat_calls
      assert_no_processor_calls
      assert_no_bundle_processor_calls
      assert_no_redundant_cache_get_calls
      assert_no_redundant_cache_set_calls
    end
  end

  def new_environment(path = fixture_path('default'))
    Sprockets::Environment.new(".") do |env|
      env.cache = Cache.new
      env.append_path(path)
      env.register_preprocessor 'application/javascript', proc { |input|
        $processor_calls[input[:filename]] ||= []
        $processor_calls[input[:filename]] << caller
        nil
      }
      env.register_bundle_processor 'application/javascript', proc { |input|
        $bundle_processor_calls[input[:filename]] ||= []
        $bundle_processor_calls[input[:filename]] << caller
        nil
      }
    end
  end

  def reset_stats!
    $file_stat_calls = {}
    $dir_entires_calls = {}
    $processor_calls = {}
    $bundle_processor_calls = {}
    $cache_get_calls = {}
    $cache_set_calls = {}
  end

  def assert_no_stat_calls
    $file_stat_calls.each do |path, callers|
      assert_equal 0, callers.size, "File.stat(#{path.inspect}) called #{callers.size} times\n\n#{format_callers(callers)}"
    end

    $dir_entires_calls.each do |path, callers|
      assert_equal 0, callers.size, "Dir.entries(#{path.inspect}) called #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_redundant_stat_calls
    $file_stat_calls.each do |path, callers|
      assert_equal 1, callers.size, "File.stat(#{path.inspect}) called #{callers.size} times\n\n#{format_callers(callers)}"
    end

    $dir_entires_calls.each do |path, callers|
      assert_equal 1, callers.size, "Dir.entries(#{path.inspect}) called #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_processor_calls
    $processor_calls.each do |path, callers|
      assert_equal 0, callers.size, "Processor ran on #{path.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_redundant_processor_calls
    $processor_calls.each do |path, callers|
      assert_equal 1, callers.size, "Processor ran on #{path.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_bundle_processor_calls
    $bundle_processor_calls.each do |path, callers|
      assert_equal 0, callers.size, "Bundle Processor ran on #{path.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_redundant_bundle_processor_calls
    $bundle_processor_calls.each do |path, callers|
      assert_equal 1, callers.size, "Bundle Processor ran on #{path.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_redundant_cache_get_calls
    $cache_get_calls.each do |key, callers|
      assert_equal 1, callers.size, "cache get #{key.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_cache_set_calls
    $cache_set_calls.each do |key, callers|
      assert_equal 0, callers.size, "cache set #{key.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def assert_no_redundant_cache_set_calls
    $cache_set_calls.each do |key, callers|
      assert_equal 1, callers.size, "cache set #{key.inspect} #{callers.size} times\n\n#{format_callers(callers)}"
    end
  end

  def format_callers(callers)
    callers.map { |c| c.join("\n") }.join("\n\n\n")
  end
end
