require 'sprockets/digest_utils'
require 'sprockets/path_digest_utils'
require 'sprockets/uri_utils'

module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on the
  # `Environment` and `CachedEnvironment` classes.
  module Caching
    include DigestUtils, PathDigestUtils, URIUtils

    def cache_dependencies
      config[:cache_dependencies]
    end

    def add_cache_dependency(uri)
      self.config = hash_reassoc(config, :cache_dependencies) do |set|
        set + Set.new([uri])
      end
    end

    def resolve_cache_dependencies(uris)
      digest(uris.map { |uri| resolve_cache_dependency(uri) })
    end

    def resolve_cache_dependency(str)
      case scheme = URI.split(str)[0]
      when "env-version"
        [VERSION, self.version]
      when "env-paths"
        self.paths
      when "file-digest"
        file_digest(parse_file_digest_uri(str))
      else
        raise TypeError, "unknown cache scheme: #{scheme}"
      end
    end

    private
      def asset_uri_cache_key(uri)
        ['asset-uri', uri]
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
