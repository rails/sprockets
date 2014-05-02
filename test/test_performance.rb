require 'sprockets_test'

$file_stat_calls = nil
class << File
  alias_method :original_stat, :stat
  def stat(filename)
    if $file_stat_calls
      $file_stat_calls[filename.to_s] ||= 0
      $file_stat_calls[filename.to_s] += 1
    end
    original_stat(filename)
  end
end

$dir_entires_calls = nil
class << Dir
  alias_method :original_entries, :entries
  def entries(dirname, *args)
    if $dir_entires_calls
      $dir_entires_calls[dirname.to_s] ||= 0
      $dir_entires_calls[dirname.to_s] += 1
    end
    original_entries(dirname, *args)
  end
end

class TestPerformance < Sprockets::TestCase
  def setup
    @env = new_environment
    reset_stats!
  end

  def teardown
    $file_stat_calls = nil
    $dir_entires_calls = nil
    $processor_calls = nil
  end

  test "simple file" do
    @env["gallery.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
  end

  test "cached simple file" do
    @env.cached["gallery.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
  end

  test "file with deps" do
    @env["mobile.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
  end

  test "cached file with deps" do
    @env.cached["mobile.js"].to_s
    assert_no_redundant_stat_calls
    assert_no_redundant_processor_calls
  end

  test "loading from cache" do
    env1, env2 = new_environment, new_environment
    cache = {}
    env1.cache = cache
    env2.cache = cache

    env1["mobile.js"]
    assert_no_redundant_processor_calls

    reset_stats!

    env2["mobile.js"]
    assert_no_redundant_stat_calls
    assert_no_processor_calls
  end

  test "loading from instance cache" do
    env = new_environment.cached
    env["mobile.js"]
    assert_no_redundant_processor_calls

    reset_stats!

    env["mobile.js"]
    assert_no_redundant_stat_calls
    assert_no_processor_calls
  end

  test "loading from shared cache" do
    env1, env2 = new_environment, new_environment
    cache = {}
    env1.cache = cache
    env2.cache = cache

    env1.cached["mobile.js"]
    assert_no_redundant_processor_calls

    reset_stats!

    env2.cached["mobile.js"]
    assert_no_redundant_stat_calls
    assert_no_processor_calls
  end

  def new_environment
    $processor_calls = {}
    Sprockets::Environment.new(".") do |env|
      env.append_path(fixture_path('default'))
      env.register_preprocessor 'application/javascript', proc { |input|
        $processor_calls[input[:filename]] ||= 0
        $processor_calls[input[:filename]] += 1
        nil
      }
    end
  end

  def reset_stats!
    $file_stat_calls = {}
    $dir_entires_calls = {}
    $processor_calls = {}
  end

  def assert_no_stat_calls
    $file_stat_calls.each do |path, count|
      assert_equal 0, count, "File.stat(#{path.inspect}) called #{count} times"
    end

    $dir_entires_calls.each do |path, count|
      assert_equal 0, count, "Dir.entries(#{path.inspect}) called #{count} times"
    end
  end

  def assert_no_redundant_stat_calls
    $file_stat_calls.each do |path, count|
      assert_equal 1, count, "File.stat(#{path.inspect}) called #{count} times"
    end

    $dir_entires_calls.each do |path, count|
      assert_equal 1, count, "Dir.entries(#{path.inspect}) called #{count} times"
    end
  end

  def assert_no_processor_calls
    $processor_calls.each do |path, count|
      assert_equal 0, count, "Processor ran on #{path.inspect} #{count} times"
    end
  end

  def assert_no_redundant_processor_calls
    $processor_calls.each do |path, count|
      assert_equal 1, count, "Processor ran on #{path.inspect} #{count} times"
    end
  end
end
