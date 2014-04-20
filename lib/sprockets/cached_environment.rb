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
      @environment = environment

      @default_external_encoding = environment.default_external_encoding

      # Copy environment attributes
      @logger            = environment.logger
      @context_class     = environment.context_class
      @cache             = environment.cache
      @trail             = environment.trail.cached
      @digest            = environment.digest
      @digest_class      = environment.digest_class
      @version           = environment.version
      @mime_types        = environment.mime_types
      @engines           = environment.engines
      @engine_mime_types = environment.engine_mime_types
      @preprocessors     = environment.preprocessors
      @postprocessors    = environment.postprocessors
      @bundle_processors = environment.bundle_processors
      @compressors       = environment.compressors
    end

    # No-op return self as cached environment.
    def cached
      self
    end
    alias_method :index, :cached

    protected
      # Cache is immutable, any methods that try to clear the cache
      # should bomb.
      def expire_cache!
        raise TypeError, "can't modify immutable cached environment"
      end

      # Cache asset building in memory and in persisted cache.
      def build_asset_hash(filename, bundle = true)
        key = [
          'asset-hash',
          self.digest.hexdigest,
          filename,
          bundle,
          file_hexdigest(filename),
          self.paths
        ]

        if hash = cache._get(key)
          digest, paths = hash.values_at(:dependency_digest, :dependency_paths)
          if dependencies_hexdigest(paths) == digest
            return hash
          end
        end

        if hash = super
          cache._set(key, hash)
          return hash
        end

        nil
      end
  end
end
