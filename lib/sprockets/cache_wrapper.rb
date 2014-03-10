module Sprockets
  class CacheWrapper
    def self.wrap(environment, cache)
      if cache.is_a?(CacheWrapper)
        cache

      # `Cache#get(key)` for Memcache
      elsif cache.respond_to?(:get)
        CacheAdapter.new(environment, cache)

      # `Cache#[key]` so `Hash` can be used
      elsif cache.respond_to?(:[])
        HashAdapter.new(environment, cache)

      # `Cache#read(key)` for `ActiveSupport::Cache` support
      elsif cache.respond_to?(:read)
        ReadWriteAdapter.new(environment, cache)

      else
        HashAdapter.new(environment, Sprockets::Cache::NullStore.new)
      end
    end

    def initialize(environment, cache)
      @environment, @cache = environment, cache
    end

    def [](key)
      get(expand_key(key))
    end

    def []=(key, value)
      set(expand_key(key), value)
    end

    def expand_key(key)
      ['sprockets', @environment.digest.hexdigest, @environment.digest.update(key).hexdigest].join('/')
    end
  end

  class GetAdapter < CacheWrapper
    def get(key)
      @cache.get(key)
    end

    def set(key, value)
      @cache.set(key, value)
    end
  end

  class HashAdapter < CacheWrapper
    def get(key)
      @cache[key]
    end

    def set(key, value)
      @cache[key] = value
    end
  end

  class ReadWriteAdapter < CacheWrapper
    def get(key)
      @cache.read(key)
    end

    def set(key, value)
      @cache.write(key, value)
    end
  end
end
