require 'sprockets/base'

module Sprockets
  # `Index` is a special cached version of `Environment`.
  #
  # The expection is that all of its file system methods are cached
  # for the instances lifetime. This makes `Index` much faster. This
  # behavior is ideal in production environments where the file system
  # is immutable.
  #
  # `Index` should not be initialized directly. Instead use
  # `Environment#index`.
  class Index < Base
    def initialize(environment)
      @environment = environment

      if environment.respond_to?(:default_external_encoding)
        @default_external_encoding = environment.default_external_encoding
      end

      # Copy environment attributes
      @logger            = environment.logger
      @context_class     = environment.context_class
      @cache             = environment.cache
      @cache_adapter     = environment.cache_adapter
      @trail             = environment.trail.index
      @digest            = environment.digest
      @digest_class      = environment.digest_class
      @version           = environment.version
      @mime_types        = environment.mime_types
      @engines           = environment.engines
      @preprocessors     = environment.preprocessors
      @postprocessors    = environment.postprocessors
      @bundle_processors = environment.bundle_processors
      @compressors       = environment.compressors

      # Initialize caches
      @assets  = {}
      @digests = {}
    end

    # No-op return self as index
    def index
      self
    end

    # Cache calls to `file_digest`
    def file_digest(pathname)
      key = pathname.to_s
      if @digests.key?(key)
        @digests[key]
      else
        @digests[key] = super
      end
    end

    # Cache `find_asset` calls
    def find_asset(path, options = {})
      options[:bundle] = true unless options.key?(:bundle)
      if asset = @assets[cache_key_for(path, options)]
        asset
      elsif asset = super
        logical_path_cache_key = cache_key_for(path, options)
        full_path_cache_key    = cache_key_for(asset.pathname, options)

        # Cache on Index
        @assets[logical_path_cache_key] = @assets[full_path_cache_key] = asset

        # Push cache upstream to Environment
        @environment.instance_eval do
          @assets[logical_path_cache_key] = @assets[full_path_cache_key] = asset
        end

        asset
      end
    end

    protected
      # Index is immutable, any methods that try to clear the cache
      # should bomb.
      def expire_index!
        raise TypeError, "can't modify immutable index"
      end

      # Cache asset building in memory and in persisted cache.
      def build_asset(path, pathname, options)
        # Memory cache
        key = cache_key_for(pathname, options)
        if @assets.key?(key)
          @assets[key]
        else
          @assets[key] = begin
            # Persisted cache
            cache_asset(key) do
              super
            end
          end
        end
      end

      # Cache helper method. Takes a `path` argument which maybe a
      # logical path or fully expanded path. The `&block` is passed
      # for finding and building the asset if its not in cache.
      def cache_asset(path)
        path_cache_key = "asset/#{path.to_s.sub(root, '')}"

        # Check cache for `path`
        if (asset = Asset.from_hash(self, cache_adapter.get(path_cache_key))) && asset.fresh?(self)
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
  end
end
