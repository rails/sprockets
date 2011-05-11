require 'sprockets/asset_pathname'
require 'sprockets/directive_processor'
require 'sprockets/environment_index'
require 'sprockets/server'
require 'sprockets/utils'
require 'fileutils'
require 'hike'
require 'logger'
require 'pathname'
require 'rack/mime'

module Sprockets
  class Environment
    include Server, Processing, StaticCompilation

    attr_accessor :logger, :context_class

    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      @trail.extensions.replace Engines::CONCATENATABLE_EXTENSIONS

      @engines = Engines.new(self)

      @logger = Logger.new($stderr)
      @logger.level = Logger::FATAL

      @context_class = Class.new(Context)

      @static_root = nil

      @mime_types = {}
      @filters = Hash.new { |h, k| h[k] = [] }
      @formats = Hash.new { |h, k| h[k] = [] }

      register_format '.css', DirectiveProcessor
      register_format '.js', DirectiveProcessor

      expire_index!
    end

    def root
      @trail.root
    end

    class ArrayProxy
      instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

      def initialize(target, &callback)
        @target, @callback = target, callback
      end

      def method_missing(sym, *args, &block)
        @callback.call()
        @target.send(sym, *args, &block)
      end
    end

    def paths
      ArrayProxy.new(@trail.paths) { expire_index! }
    end

    attr_reader :engines

    def extensions
      ArrayProxy.new(@trail.extensions) { expire_index! }
    end

    def precompile(*paths)
      index.precompile(*paths)
    end

    def index
      EnvironmentIndex.new(self, @trail, @static_root)
    end

    def resolve(logical_path, options = {}, &block)
      index.resolve(logical_path, options, &block)
    end

    def find_asset(logical_path)
      logical_path = Pathname.new(logical_path)

      if asset = find_fresh_asset_from_cache(logical_path)
        asset
      elsif asset = index.find_asset(logical_path)
        @cache[logical_path.to_s] = asset
      end
    end
    alias_method :[], :find_asset

    protected
      def expire_index!
        @cache = {}
      end

      def find_fresh_asset_from_cache(logical_path)
        if asset = @cache[logical_path.to_s]
          if Utils.path_fingerprint(logical_path)
            asset
          elsif asset.stale?
            logger.warn "[Sprockets] #{logical_path} #{asset.digest} stale"
            nil
          else
            logger.info "[Sprockets] #{logical_path} #{asset.digest} fresh"
            asset
          end
        else
          nil
        end
      end
  end
end
