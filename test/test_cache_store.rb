require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'sprockets/cache'
require 'sprockets/cache/file_store'
require 'sprockets/cache/memory_store'
require 'sprockets/cache/null_store'

module CacheStoreNullTests
  def test_read
    refute @store.get("foo")
  end

  def test_write
    result = @store.set("foo", "bar")
    assert_equal "bar", result
  end

  def test_write_and_read_miss
    @store.set("foo", "bar")
    refute @store.get("foo")
  end

  def test_fetch
    result = @store.fetch("foo") { "bar" }
    assert_equal "bar", result
  end
end

module CacheStoreTests
  def test_read_miss
    refute @store.get("missing")
  end

  def test_write
    result = @store.set("foo", "bar")
    assert_equal "bar", result
  end

  def test_write_and_read_hit
    @store.set("foo", "bar")
    assert_equal "bar", @store.get("foo")
  end

  def test_multiple_write_and_read_hit
    @store.set("foo", "1")
    @store.set("bar", "2")
    @store.set("baz", "3")

    assert_equal "1", @store.get("foo")
    assert_equal "2", @store.get("bar")
    assert_equal "3", @store.get("baz")
  end

  def test_large_write_and_read_hit
    data = ("a"..."zzz").to_a.join
    @store.set("foo", data)
    assert_equal data, @store.get("foo")
  end

  def test_delete
    @store.set("foo", "bar")
    assert_equal "bar", @store.get("foo")
    @store.set("foo", nil)
    assert_equal nil, @store.get("foo")
  end

  def test_fetch
    result = @store.fetch("user") { "josh" }
    assert_equal "josh", result
  end
end

class TestNullStore < MiniTest::Test
  def setup
    @_store = Sprockets::Cache::NullStore.new
    @store = Sprockets::Cache.new(Sprockets::Cache::NullStore.new)
  end

  def test_inspect
    assert_equal "#<Sprockets::Cache local=#<Sprockets::Cache::MemoryStore size=0/1024> store=#<Sprockets::Cache::NullStore>>", @store.inspect
    assert_equal "#<Sprockets::Cache::NullStore>", @_store.inspect
  end

  include CacheStoreNullTests
end

class TestMemoryStore < MiniTest::Test
  def setup
    @_store = Sprockets::Cache::MemoryStore.new
    @store = Sprockets::Cache.new(@_store)
  end

  def test_inspect
    assert_equal "#<Sprockets::Cache::MemoryStore size=0/1000>", @_store.inspect
  end

  include CacheStoreTests

  def test_get_with_lru
    @_store.set(:a, 1)
    @_store.set(:b, 2)
    @_store.set(:c, 3)
    assert_equal [1, 2, 3], @_store.instance_variable_get(:@cache).values
    @_store.get(:a)
    @_store.set(:d, 4)
    assert_equal [2, 3, 1, 4], @_store.instance_variable_get(:@cache).values
  end

  def test_set_with_lru
    @_store.set(:a, 1)
    @_store.set(:b, 2)
    @_store.set(:c, 3)
    assert_equal [1, 2, 3], @_store.instance_variable_get(:@cache).values
    @_store.set(:a, 1)
    @_store.set(:d, 4)
    assert_equal [2, 3, 1, 4], @_store.instance_variable_get(:@cache).values
  end
end

class TestZeroMemoryStore < MiniTest::Test
  def setup
    @_store = Sprockets::Cache::MemoryStore.new(0)
    @store = Sprockets::Cache.new(@_store)
  end

  def test_inspect
    assert_equal "#<Sprockets::Cache::MemoryStore size=0/0>", @_store.inspect
  end

  include CacheStoreNullTests
end

class TestFileStore < MiniTest::Test
  def setup
    @root = Dir::mktmpdir "sprockets-file-store"
    @_store = Sprockets::Cache::FileStore.new(@root)
    @store = Sprockets::Cache.new(@_store)
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def test_inspect
    Dir::mktmpdir "sprockets-file-store-inspect" do |dir|
      store = Sprockets::Cache::FileStore.new(dir)
      assert_equal "#<Sprockets::Cache::FileStore size=0/26214400>", store.inspect
    end
  end

  def test_corrupted_read
    File.write(File.join(@root, "corrupt.cache"), "w") do |f|
      f.write("corrupt")
    end
    refute @_store.get("corrupt")
  end

  include CacheStoreTests
end

class TestZeroFileStore < MiniTest::Test
  def setup
    @tmpdir = Dir::mktmpdir "sprockets-file-store-zero"
    @_store = Sprockets::Cache::FileStore.new(@tmpdir, 0)
    @store = Sprockets::Cache.new(@_store)
  end

  def teardown
    FileUtils.rm_rf @tmpdir
  end

  def test_inspect
    Dir.mktmpdir "sprockets-file-store-inspect" do |dir|
      store = Sprockets::Cache::FileStore.new(dir, 0)
      assert_equal "#<Sprockets::Cache::FileStore size=0/0>", store.inspect
    end
  end

  include CacheStoreNullTests
end
