require 'sprockets_test'
require 'tmpdir'

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

class TestNullStore < Sprockets::TestCase
  def setup
    @store = Sprockets::Cache.new(Sprockets::Cache::NullStore.new)
  end

  include CacheStoreNullTests
end

class TestMemoryStore < Sprockets::TestCase
  def setup
    @store = Sprockets::Cache.new(Sprockets::Cache::MemoryStore.new)
  end

  include CacheStoreTests
end

class TestZeroMemoryStore < Sprockets::TestCase
  def setup
    @store = Sprockets::Cache.new(Sprockets::Cache::MemoryStore.new(0))
  end

  include CacheStoreNullTests
end

class TestFileStore < Sprockets::TestCase
  def setup
    @store = Sprockets::Cache.new(Sprockets::Cache::FileStore.new(File.join(Dir::tmpdir, "sprockets-file-store")))
  end

  include CacheStoreTests
end

class TestZeroFileStore < Sprockets::TestCase
  def setup
    @store = Sprockets::Cache.new(Sprockets::Cache::FileStore.new(File.join(Dir::tmpdir, "sprockets-file-store-zero"), 0))
  end

  include CacheStoreNullTests
end
