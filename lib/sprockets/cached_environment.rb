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
      @uris    = Hash.new { |h, k| h[k] = _load(k) }
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

    # Internal: Cache Environment#load
    alias_method :_load, :load
    def load(uri)
      @uris[uri]
    end

    protected
      def asset_digest_cache_key(uri, digest)
        [
          'asset-uri-digest',
          VERSION,
          self.version,
          self.paths,
          uri,
          digest
        ]
      end

      def asset_uri_cache_key(uri)
        [
          'asset-uri',
          VERSION,
          self.version,
          uri
        ]
      end

      def load_asset_by_id_uri(uri)
        cache.fetch(asset_uri_cache_key(uri)) do
          super
        end
      end

      def load_asset_by_uri(uri)
        filename, _ = parse_asset_uri(uri)

        if paths = cache._get(asset_digest_cache_key(uri, file_digest(filename)))
          if id_uri = cache.__get(asset_digest_cache_key(uri, files_digest(paths)))
            if asset = cache.__get(asset_uri_cache_key(id_uri))
              return asset
            end
          end
        end

        asset = super

        paths, digest = asset[:metadata].values_at(:dependency_paths, :dependency_sources_digest)
        cache.__set(asset_uri_cache_key(asset[:uri]), asset)
        cache.__set(asset_digest_cache_key(uri, digest), asset[:uri])
        cache._set(asset_digest_cache_key(uri, file_digest(filename)), paths)

        asset
      end

    private
      # Cache is immutable, any methods that try to change the runtime config
      # should bomb.
      def config=(config)
        raise RuntimeError, "can't modify immutable cached environment"
      end
  end

  # Deprecated
  Index = CachedEnvironment
end
