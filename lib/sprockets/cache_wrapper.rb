require 'digest/sha1'

module Sprockets
  class CacheWrapper
    def self.wrap(cache)
      if cache.is_a?(CacheWrapper)
        cache

      # `Cache#get(key)` for Memcache
      elsif cache.respond_to?(:get)
        GetWrapper.new(cache)

      # `Cache#[key]` so `Hash` can be used
      elsif cache.respond_to?(:[])
        HashWrapper.new(cache)

      # `Cache#read(key)` for `ActiveSupport::Cache` support
      elsif cache.respond_to?(:read)
        ReadWriteWrapper.new(cache)

      else
        HashWrapper.new(Sprockets::Cache::NullStore.new)
      end
    end

    def initialize(cache)
      @cache = cache
    end

    def fetch(key)
      expanded_key = expand_key(key)
      value = get(expanded_key)
      if !value
        value = yield
        set(expanded_key, value)
      end
      value
    end

    def [](key)
      get(expand_key(key))
    end

    def []=(key, value)
      set(expand_key(key), value)
    end

    def expand_key(key)
      digest = Digest::SHA1.new
      hash_key!(digest, key)
      ['sprockets', digest.hexdigest].join('/')
    end

    def hash_key!(digest, obj)
      case obj
      when String
        digest.update(obj)
      when Array
        obj.each { |o| hash_key!(digest, o) }
      else
        raise ArgumentError, "could not hash #{obj.class}"
      end
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
