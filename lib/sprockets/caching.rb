require 'sprockets/bundled_asset'
require 'sprockets/static_asset'

module Sprockets
  module Caching
    private
      def cache_get(key)
        return unless cache

        if cache.respond_to?(:get)
          cache.get(key)
        elsif cache.respond_to?(:[])
          cache[key]
        elsif cache.respond_to?(:read)
          cache.read(key)
        else
          nil
        end
      end

      def cache_set(key, value)
        return unless cache

        if cache.respond_to?(:set)
          cache.set(key, value)
        elsif cache.respond_to?(:[]=)
          cache[key] = value
        elsif cache.respond_to?(:write)
          cache.write(key, value)
        end

        value
      end

      def cache_get_asset(logical_path)
        json = cache_get(logical_path)

        if json.is_a?(String)
          asset = Sprockets::BundledAsset.from_json(self, json)

          if asset.stale?
            nil
          else
            logger.debug "Loading #{logical_path} from cache"
            asset
          end
        else
          nil
        end
      end

      def cache_set_asset(logical_path, asset)
        logger.debug "Storing #{logical_path} to cache"
        cache_set(logical_path, asset.to_json)
        asset
      end

      def cache_asset(logical_path)
        if asset = cache_get_asset(logical_path)
          asset
        elsif asset = yield
          cache_set_asset(logical_path.to_s, asset)
          if logical_path.to_s != asset.pathname.to_s
            cache_set_asset(asset.pathname.to_s, asset)
          end
          asset
        end
      end
  end
end
