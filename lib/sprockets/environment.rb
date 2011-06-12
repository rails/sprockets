require 'sprockets/base'
require 'sprockets/context'
require 'sprockets/directive_processor'
require 'sprockets/index'

require 'hike'
require 'logger'
require 'pathname'
require 'tilt'

module Sprockets
  class Environment < Base
    def initialize(root = ".")
      @trail = Hike::Trail.new(root)

      @logger = Logger.new($stderr)
      @logger.level = Logger::FATAL

      @context_class = Class.new(Context)

      require 'digest/md5'
      @digest_class = ::Digest::MD5
      @digest_key_prefix = ''

      @static_root = nil

      @engines = Sprockets.engines
      @trail.extensions.replace(engine_extensions)

      @mime_types = {}
      @processors = Hash.new { |h, k| h[k] = [] }
      @bundle_processors = Hash.new { |h, k| h[k] = [] }

      register_mime_type 'text/css', '.css'
      register_mime_type 'application/javascript', '.js'

      register_processor 'text/css', DirectiveProcessor
      register_processor 'application/javascript', DirectiveProcessor

      register_bundle_processor 'text/css', CharsetNormalizer

      expire_index!
    end

    def index
      Index.new(self)
    end

    def find_asset(logical_path, options = {})
      cache_asset(logical_path) { super }
    end

    protected
      def cache_get_asset(logical_path)
        if (asset = @assets[logical_path]) && !asset.stale?
          asset
        else
          super
        end
      end

      def cache_set_asset(logical_path, asset)
        @assets[logical_path] = asset
        super
      end

      def expire_index!
        @digest = compute_digest
        @assets = {}
      end
  end
end
