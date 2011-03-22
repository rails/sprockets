require 'hike'
require 'logger'
require 'thread'
require 'tilt'

module Sprockets
  class Environment
    DEFAULT_ENGINE_EXTENSIONS = %w( .coffee .erb .less .sass .scss .str )
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    @template_mappings = {}

    def self.register(ext, klass)
      ext = ext.to_s.sub(/^\./, '').downcase
      @template_mappings[ext] = klass
    end

    def self.lookup_engine(ext)
      ext = ext.to_s.sub(/^\./, '').downcase
      @template_mappings[ext] || Tilt[ext]
    end

    attr_accessor :logger

    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      engine_extensions.replace(DEFAULT_ENGINE_EXTENSIONS + CONCATENATABLE_EXTENSIONS)

      @logger = Logger.new($stderr)
      @logger.level = Logger::FATAL

      @cache = {}
      @lock  = nil

      @static_root = nil

      @server = Server.new(self)
    end

    def multithread
      @lock ? true : false
    end

    def multithread=(val)
      @lock = val ? Mutex.new : nil
    end

    def static_root
      @static_root
    end

    def static_root=(root)
      @static_root = root ? Pathname.new(root) : nil
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def engine_extensions
      @trail.extensions
    end

    def call(env)
      @server.call(env)
    end

    def url(logical_path)
      logical_path = Pathname.new(logical_path)

      if asset = find_asset(logical_path)
        basename = logical_path.basename_without_extensions +
          "-" + asset.digest +
          logical_path.extensions.join

        if logical_path.dirname == '.'
          basename
        else
          File.join(logical_path.dirname, basename)
        end
      else
        logical_path.to_s
      end
    end

    def resolve(logical_path, options = {})
      if block_given?
        @trail.find(logical_path.to_s, options) do |path|
          yield Pathname.new(path)
        end
      else
        resolve(logical_path, options) do |pathname|
          return pathname
        end
        raise FileNotFound, "couldn't find file '#{logical_path}'"
      end
    end

    def find_asset(logical_path)
      logger.debug "[Sprockets] Finding asset for #{logical_path}"

      logical_path = Pathname.new(logical_path)

      if asset = find_fresh_asset_from_cache(logical_path)
        asset
      elsif @lock
        @lock.synchronize do
          if asset = find_fresh_asset_from_cache(logical_path)
            asset
          elsif asset = build_asset(logical_path)
            @cache[logical_path.to_s] = asset
          end
        end
      elsif asset = build_asset(logical_path)
        @cache[logical_path.to_s] = asset
      end
    end

    alias_method :[], :find_asset

    protected
      def find_fresh_asset_from_cache(logical_path)
        if asset = @cache[logical_path.to_s]
          if logical_path.fingerprint
            logger.debug "[Sprockets] Asset #{logical_path} is cached"
            asset
          elsif asset.stale?
            logger.warn "[Sprockets] Asset #{logical_path} #{asset.digest} is stale"
            nil
          else
            logger.info "[Sprockets] Asset #{logical_path} #{asset.digest} is fresh"
            asset
          end
        else
          logger.debug "[Sprockets] Asset #{logical_path} is not cached"
          nil
        end
      end

      def build_asset(logical_path)
        logger.info "[Sprockets] Building asset for #{logical_path}"
        find_static_asset(logical_path) || find_asset_in_load_path(logical_path)
      end

      def find_static_asset(logical_path)
        return nil unless static_root

        pathname = Pathname.new(File.join(static_root.to_s, logical_path.to_s))

        if !pathname.fingerprint
          basename = "#{pathname.basename_without_extensions}-#{'[0-9a-f]'*7}*"
          basename = "#{basename}#{pathname.extensions.join}"

          Dir[File.join(pathname.dirname, basename)].each do |filename|
            return StaticAsset.new(filename)
          end
        end

        if pathname.exist?
          return StaticAsset.new(pathname)
        end

        nil
      end

      def find_asset_in_load_path(logical_path)
        if fingerprint = logical_path.fingerprint
          pathname = resolve(logical_path.to_s.sub("-#{fingerprint}", ''))
        else
          pathname = resolve(logical_path)
        end
      rescue FileNotFound
        nil
      else
        if concatenatable?(pathname)
          asset = ConcatenatedAsset.new(self, pathname)
        else
          asset = StaticAsset.new(pathname)
        end

        if fingerprint && fingerprint != asset.digest
          logger.error "[Sprockets] Couldn't find #{logical_path}"
          return nil
        end

        asset
      end

      def concatenatable?(pathname)
        CONCATENATABLE_EXTENSIONS.include?(pathname.format_extension)
      end
  end
end
