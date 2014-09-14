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

      @cache    = environment.cache
      @stats    = Hash.new { |h, k| h[k] = _stat(k) }
      @entries  = Hash.new { |h, k| h[k] = _entries(k) }
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

    protected
      def asset_hash_cache_key(filename, digest, options)
        [
          'asset-hash',
          VERSION,
          self.version,
          filename,
          digest,
          options
        ]
      end

      def asset_digest_cache_key(filename, options)
        [
          'asset-digest',
          VERSION,
          self.version,
          filename,
          options,
          file_hexdigest(filename),
          self.paths
        ]
      end

      def asset_etag_uri_cache_key(uri)
        [
          'asset-etag-uri',
          VERSION,
          self.version,
          uri
        ]
      end

      def build_asset_by_etag_uri(uri)
        cache.fetch(asset_etag_uri_cache_key(uri)) do
          super
        end
      end

      # def build_asset_by_uri(uri)
      #   filename, _ = parse_asset_uri(uri)
      #
      #   dep_graph_key = [
      #     'asset-uri-dep-graph',
      #     VERSION,
      #     self.version,
      #     self.paths,
      #     uri,
      #     file_hexdigest(filename)
      #   ]
      #
      #   paths, digest, etag_uri = cache._get(dep_graph_key)
      #   if paths && digest && etag_uri
      #     if dependencies_hexdigest(paths) == digest
      #       if asset = cache._get(asset_etag_uri_cache_key(etag_uri))
      #         return asset
      #       end
      #     end
      #   end
      #
      #   asset = super(uri)
      #
      #   etag_uri = asset[:uri]
      #   digest, paths = asset[:metadata].values_at(:dependency_digest, :dependency_paths)
      #   cache._set(dep_graph_key, [paths, digest, etag_uri])
      #
      #   cache.fetch(asset_etag_uri_cache_key(etag_uri)) { asset }
      #
      #   asset
      # end

      # Cache asset building in memory and in persisted cache.
      def build_asset_hash(filename, options)
        digest_key = asset_digest_cache_key(filename, options)

        if digest = cache._get(digest_key)
          hash_key = asset_hash_cache_key(filename, digest, options)

          if hash = cache._get(hash_key)
            digest, paths = hash[:metadata].values_at(:dependency_digest, :dependency_paths)
            if dependencies_hexdigest(paths) == digest
              return hash
            end
          end
        end

        hash = super
        cache._set(digest_key, hash[:digest])

        # Push into asset etag cache
        cache.fetch(asset_hash_cache_key(filename, hash[:digest], options)) { hash }
        cache.fetch(asset_etag_uri_cache_key(hash[:uri])) { hash }

        hash
      end

    private
      # Cache is immutable, any methods that try to clear the cache
      # should bomb.
      def mutate_config(*args)
        raise RuntimeError, "can't modify immutable cached environment"
      end
  end
end
