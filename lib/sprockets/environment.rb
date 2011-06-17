require 'sprockets/base'
require 'sprockets/context'
require 'sprockets/directive_processor'
require 'sprockets/index'
require 'sprockets/safety_colons'

require 'hike'
require 'logger'
require 'pathname'
require 'tilt'

module Sprockets
  class Environment < Base
    def initialize(root = ".")
      @trail = Hike::Trail.new(root)

      self.logger = Logger.new($stderr)
      self.logger.level = Logger::FATAL

      @context_class = Class.new(Context)

      require 'digest/md5'
      @digest_class = ::Digest::MD5
      @version = ''

      @static_root = nil

      @engines = Sprockets.engines
      @trail.extensions.replace(engine_extensions)

      @mime_types = {}
      @preprocessors     = Hash.new { |h, k| h[k] = [] }
      @postprocessors    = Hash.new { |h, k| h[k] = [] }
      @bundle_processors = Hash.new { |h, k| h[k] = [] }

      register_mime_type 'text/css', '.css'
      register_mime_type 'application/javascript', '.js'

      register_preprocessor 'text/css', DirectiveProcessor
      register_preprocessor 'application/javascript', DirectiveProcessor

      register_postprocessor 'application/javascript', SafetyColons
      register_bundle_processor 'text/css', CharsetNormalizer

      expire_index!

      yield self if block_given?
    end

    def index
      Index.new(self)
    end

    def find_asset(path, options = {})
      cache_asset(path) { super }
    end

    protected
      def cache_asset(path)
        if (asset = @assets[path.to_s]) && asset.fresh?
          asset
        elsif asset = super
          @assets[path.to_s] = @assets[asset.pathname.to_s] = asset
          asset
        end
      end

      def expire_index!
        @digest = nil
        @assets = {}
      end
  end
end
