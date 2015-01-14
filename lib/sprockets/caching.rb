require 'sprockets/digest_utils'
require 'sprockets/path_digest_utils'
require 'sprockets/uri_utils'

module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on the
  # `Environment` and `CachedEnvironment` classes.
  module Caching
    include DigestUtils, PathDigestUtils, URIUtils

    def resolve_cache_dependencies(uris)
      digest(uris.map { |uri| resolve_cache_dependency(uri) })
    end

    def resolve_cache_dependency(str)
      case scheme = URI.split(str)[0]
      when "file-digest"
        file_digest(parse_file_digest_uri(str))
      else
        raise TypeError, "unknown cache scheme: #{scheme}"
      end
    end

    private
      def asset_uri_cache_key(uri)
        [
          'asset-uri',
          # TODO: Include version in global cache_dependencies
          VERSION,
          # TODO: Include version in global cache_dependencies
          self.version,
          uri
        ]
      end

      def get_asset_dependency_graph_cache(key)
        return unless cached = cache._get(key)
        cache_uris, digest, uri = cached

        if resolve_cache_dependencies(cache_uris) == digest
          cache._get(asset_uri_cache_key(uri))
        end
      end

      def set_asset_dependency_graph_cache(key, asset)
        uri = asset[:uri]
        digest, cache_uris = asset[:metadata].values_at(:cache_dependencies_digest, :cache_dependencies)
        cache._set(key, [cache_uris, digest, uri])
        cache.fetch(asset_uri_cache_key(uri)) { asset }
        asset
      end
  end
end
