require 'sprockets/bundled_asset'
require 'sprockets/static_asset'

module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on
  # the `Environment` and `Index` classes.
  module Caching
    # Return `Asset` instance for serialized `Hash`.
    def asset_from_hash(hash)
      case hash['class']
      when 'BundledAsset'
        BundledAsset.from_hash(self, hash)
      when 'StaticAsset'
        StaticAsset.from_hash(self, hash)
      else
        nil
      end
    end

    protected
      # Cache helper method. Takes a `path` argument which maybe a
      # logical path or fully expanded path. The `&block` is passed
      # for finding and building the asset if its not in cache.
      def cache_asset(path)
        # If `cache` is not set, return fast
        if cache.nil?
          yield

        # Check cache for `path`
        elsif asset = cache_get_asset(path)
          asset

         # Otherwise yield block that slowly finds and builds the asset
        elsif asset = yield
          # Save the asset to at its path
          cache_set_asset(path.to_s, asset)

          # Since path maybe a logical or full pathname, save the
          # asset its its full path too
          if path.to_s != asset.pathname.to_s
            cache_set_asset(asset.pathname.to_s, asset)
          end

          asset
        end
      end

    private
      def cache_key_namespace
        'sprockets'
      end

      # Removes `Environment#root` from key and prepends
      # `Environment#cache_key_namespace`.
      def cache_key_for(path)
        File.join(cache_key_namespace, path.sub(root, ''))
      end

      # Gets asset from cache and unserializes it
      def cache_get_asset(path)
        hash = cache_get(cache_key_for(path))

        if hash.is_a?(Hash)
          asset = asset_from_hash(hash)

          if asset.fresh?
            asset
          end
        else
          nil
        end
      end

      # Serializes and saves asset to cache
      def cache_set_asset(path, asset)
        hash = {}
        asset.encode_with(hash)
        cache_set(cache_key_for(path), hash)
        asset
      end

      # Low level cache getter for `key`. Checks a number of supported
      # cache interfaces.
      def cache_get(key)
        # `Cache#get(key)` for Memcache
        if cache.respond_to?(:get)
          cache.get(key)

        # `Cache#[key]` so `Hash` can be used
        elsif cache.respond_to?(:[])
          cache[key]

        # `Cache#read(key)` for `ActiveSupport::Cache` support
        elsif cache.respond_to?(:read)
          cache.read(key)

        else
          nil
        end
      end

      # Low level cache setter for `key`. Checks a number of supported
      # cache interfaces.
      def cache_set(key, value)
        # `Cache#set(key, value)` for Memcache
        if cache.respond_to?(:set)
          cache.set(key, value)

        # `Cache#[key]=value` so `Hash` can be used
        elsif cache.respond_to?(:[]=)
          cache[key] = value

        # `Cache#write(key, value)` for `ActiveSupport::Cache` support
        elsif cache.respond_to?(:write)
          cache.write(key, value)
        end

        value
      end
  end
end
