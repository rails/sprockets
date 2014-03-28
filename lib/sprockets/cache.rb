require 'digest/sha1'

module Sprockets
  class Cache
    autoload :FileStore,   'sprockets/cache/file_store'
    autoload :MemoryStore, 'sprockets/cache/memory_store'
    autoload :NullStore,   'sprockets/cache/null_store'

    def initialize(cache = nil)
      @cache_wrapper = get_cache_wrapper(cache)
    end

    def fetch(key)
      expanded_key = expand_key(key)
      value = @cache_wrapper.get(expanded_key)
      if !value
        value = yield
        @cache_wrapper.set(expanded_key, value)
      end
      value
    end

    def [](key)
      @cache_wrapper.get(expand_key(key))
    end

    def []=(key, value)
      @cache_wrapper.set(expand_key(key), value)
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

    private
      def get_cache_wrapper(cache)
        if cache.is_a?(Cache)
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
          cache = Sprockets::Cache::NullStore.new
          HashWrapper.new(cache)
        end
      end

      class Wrapper < Struct.new(:cache)
      end

      class GetWrapper < Wrapper
        def get(key)
          cache.get(key)
        end

        def set(key, value)
          cache.set(key, value)
        end
      end

      class HashWrapper < Wrapper
        def get(key)
          cache[key]
        end

        def set(key, value)
          cache[key] = value
        end
      end

      class ReadWriteWrapper < Wrapper
        def get(key)
          cache.read(key)
        end

        def set(key, value)
          cache.write(key, value)
        end
      end
  end
end
