require 'sprockets/base'

module Sprockets
  # `Cached` is a special cached version of `Environment`.
  #
  # The expection is that all of its file system methods are cached
  # for the instances lifetime. This makes `Cached` much faster. This
  # behavior is ideal in production environments where the file system
  # is immutable.
  #
  # `Cached` should not be initialized directly. Instead use
  # `Environment#cached`.
  class CachedEnvironment < Base
    def initialize(environment)
      initialize_configuration(environment)

      @cache   = environment.cache
      @stats   = Hash.new { |h, k| h[k] = _stat(k) }
      @entries = Hash.new { |h, k| h[k] = _entries(k) }
      @digests = Hash.new { |h, k| h[k] = _file_digest(k) }
    end

    # No-op return self as cached environment.
    def cached
      self
    end
    alias_method :index, :cached

    # Internal: Cache Environment#entries
    alias_method :_entries, :entries
    def entries(path)
      @entries[path]
    end

    # Internal: Cache Environment#stat
    alias_method :_stat, :stat
    def stat(path)
      @stats[path]
    end

    # Internal: Cache Environment#file_digest
    alias_method :_file_digest, :file_digest
    def file_digest(path)
      @digests[path]
    end

    protected
      def asset_dependency_graph_cache_key(uri)
        filename, _ = AssetURI.parse(uri)
        [
          'asset-uri-dep-graph',
          VERSION,
          self.version,
          self.paths,
          uri,
          file_digest(filename)
        ]
      end

      def asset_digest_uri_cache_key(uri)
        [
          'asset-digest-uri',
          VERSION,
          self.version,
          uri
        ]
      end

      def build_asset_by_digest_uri(uri)
        cache.fetch(asset_digest_uri_cache_key(uri)) do
          super
        end
      end

      def build_asset_by_uri(uri)
        dep_graph_key = asset_dependency_graph_cache_key(uri)

        dependency_paths, dependency_digest, digest_uri = cache._get(dep_graph_key)
        if dependency_paths && dependency_digest && digest_uri
          if dependencies_hexdigest(dependency_paths) == dependency_digest
            if asset = cache._get(asset_digest_uri_cache_key(digest_uri))
              return asset
            end
          end
        end

        asset = super

        dependency_digest, dependency_paths = asset[:metadata].values_at(:dependency_digest, :dependency_paths)
        cache._set(dep_graph_key, [dependency_paths, dependency_digest, asset[:uri]])
        cache.fetch(asset_digest_uri_cache_key(asset[:uri])) { asset }

        asset
      end

    private
      # Cache is immutable, any methods that try to clear the cache
      # should bomb.
      def mutate_config(*args)
        raise RuntimeError, "can't modify immutable cached environment"
      end
  end
end
