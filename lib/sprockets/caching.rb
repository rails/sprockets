module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on
  # the `Environment` and `Index` classes.
  module Caching
    attr_reader :cache_adapter

    protected
      # Cache helper method. Takes a `path` argument which maybe a
      # logical path or fully expanded path. The `&block` is passed
      # for finding and building the asset if its not in cache.
      def cache_asset(path)
        path_cache_key = "asset/#{path.to_s.sub(root, '')}"

        # If `cache` is not set, return fast
        if cache.nil?
          yield

        # Check cache for `path`
        elsif (asset = Asset.from_hash(self, cache_adapter.get(path_cache_key))) && asset.fresh?(self)
          asset

         # Otherwise yield block that slowly finds and builds the asset
        elsif asset = yield
          hash = {}
          asset.encode_with(hash)

          # Save the asset to its path
          cache_adapter.set(path_cache_key, hash)

          # Since path maybe a logical or full pathname, save the
          # asset its its full path too
          if path.to_s != asset.pathname.to_s
            pathname_cache_key = "asset/#{asset.pathname.to_s.sub(root, '')}"
            cache_adapter.set(pathname_cache_key, hash)
          end

          asset
        end
      end

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
