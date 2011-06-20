require 'sprockets/base'

module Sprockets
  class Index < Base
    def initialize(environment)
      @logger            = environment.logger
      @context_class     = environment.context_class
      @cache             = environment.cache
      @trail             = environment.trail.index
      @static_root       = environment.static_root
      @digest            = environment.digest
      @digest_class      = environment.digest_class
      @version           = environment.version
      @mime_types        = environment.mime_types
      @engines           = environment.engines
      @preprocessors     = environment.preprocessors
      @postprocessors    = environment.postprocessors
      @bundle_processors = environment.bundle_processors

      # Caches
      @assets  = {}
      @digests = {}
    end

    def index
      self
    end

    def file_digest(pathname, data = nil)
      memoize(@digests, pathname.to_s) { super }
    end

    def find_asset(path, options = {})
      if asset = @assets[path.to_s]
        asset
      elsif asset = super
        @assets[path.to_s] = @assets[asset.pathname.to_s] = asset
        asset
      end
    end

    protected
      def expire_index!
        raise TypeError, "can't modify immutable index"
      end

      def build_asset(path, pathname, options)
        @assets[pathname.to_s] ||= cache_asset(pathname.to_s) { super }
      end

    private
      def memoize(hash, key)
        hash.key?(key) ? hash[key] : hash[key] = yield
      end
  end
end
