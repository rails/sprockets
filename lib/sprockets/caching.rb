require 'sprockets/bundled_asset'
require 'sprockets/static_asset'
require 'multi_json'

module Sprockets
  module Caching
    def asset_from_json(json)
      hash = MultiJson.decode(json)

      case hash['class']
      when 'BundledAsset'
        Sprockets::BundledAsset.from_json(self, hash)
      when 'StaticAsset'
        Sprockets::StaticAsset.from_json(self, hash)
      else
        nil
      end
    end

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
          asset = asset_from_json(json)

          if !asset.stale?
            asset
          end
        else
          nil
        end
      end

      def cache_set_asset(logical_path, asset)
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
