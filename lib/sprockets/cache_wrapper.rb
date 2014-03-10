module Sprockets
  class CacheWrapper
    def self.wrap(environment, cache)
      if cache.is_a?(CacheWrapper)
        cache

      # `Cache#get(key)` for Memcache
      elsif cache.respond_to?(:get)
        GetWrapper.new(environment, cache)

      # `Cache#[key]` so `Hash` can be used
      elsif cache.respond_to?(:[])
        HashWrapper.new(environment, cache)

      # `Cache#read(key)` for `ActiveSupport::Cache` support
      elsif cache.respond_to?(:read)
        ReadWriteWrapper.new(environment, cache)

      else
        HashWrapper.new(environment, Sprockets::Cache::NullStore.new)
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

  class IndexWrapper < CacheWrapper
    def initialize(*args)
      @local = {}
      super
    end

    def [](key)
      @local[key] ||= @cache[key]
    end

    def []=(key, value)
      @local[key] = @cache[key] = value
    end
  end

  class GetWrapper < CacheWrapper
    def get(key)
      @cache.get(key)
    end

    def set(key, value)
      @cache.set(key, value)
    end
  end

  class HashWrapper < CacheWrapper
    def get(key)
      @cache[key]
    end

    def set(key, value)
      @cache[key] = value
    end
  end

  class ReadWriteWrapper < CacheWrapper
    def get(key)
      @cache.read(key)
    end

    def set(key, value)
      @cache.write(key, value)
    end
  end
end
