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
      def asset_dependency_graph_cache_key(uri)
        filename, _ = parse_asset_uri(uri)
        [
          'asset-uri-dep-graph',
          VERSION,
          self.version,
          self.paths,
          uri,
          file_digest(filename)
        ]
      end

      def load_asset_by_id_uri(uri)
        cache.fetch(asset_uri_cache_key(uri)) do
          super
        end
      end

      def load_asset_by_uri(uri)
        dep_graph_key = asset_dependency_graph_cache_key(uri)

        if asset = get_asset_dependency_graph_cache(dep_graph_key)
          asset
        else
          asset = super
          set_asset_dependency_graph_cache(dep_graph_key, asset)
          asset
        end
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
