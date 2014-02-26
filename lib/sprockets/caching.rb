module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on
  # the `Environment` and `Index` classes.
  module Caching
    attr_reader :cache_adapter

    private
      def make_cache_adapter(cache)
        # `Cache#get(key)` for Memcache
        if cache.respond_to?(:get)
          CacheAdapter.new(self, cache)

        # `Cache#[key]` so `Hash` can be used
        elsif cache.respond_to?(:[])
          HashAdapter.new(self, cache)

        # `Cache#read(key)` for `ActiveSupport::Cache` support
        elsif cache.respond_to?(:read)
          ReadWriteAdapter.new(self, cache)

        else
          HashAdapter.new(self, Sprockets::Cache::NullStore.new)
        end
      end

      class CacheAdapter
        def initialize(environment, cache)
          @environment, @cache = environment, cache
        end

        def get(key)
          _get(expand_key(key))
        end

        def set(key, value)
          _set(expand_key(key), value)
        end

        def expand_key(key)
          ['sprockets', @environment.digest.hexdigest, @environment.digest.update(key).hexdigest].join('/')
        end
      end

      class GetAdapter < CacheAdapter
        def _get(key); @cache.get(key); end
        def _set(key, value); @cache.set(key, value); end
      end

      class HashAdapter < CacheAdapter
        def _get(key); @cache[key]; end
        def _set(key, value); @cache[key] = value; end
      end

      class ReadWriteAdapter < CacheAdapter
        def _get(key); @cache.read(key); end
        def _set(key, value); @cache.write(key, value); end
      end
  end
end
