require 'sprockets/concatenated_asset'
require 'sprockets/engine_pathname'
require 'sprockets/errors'
require 'sprockets/static_asset'
require 'sprockets/utils'
require 'pathname'
require 'set'

module Sprockets
  class PathIndex
    attr_reader :logger, :context, :engines, :css_compressor, :js_compressor

    def initialize(environment, trail)
      @logger         = environment.logger
      @context        = environment.context
      @engines        = environment.engines
      @css_compressor = environment.css_compressor
      @js_compressor  = environment.js_compressor

      @trail  = trail.index
      @assets = {}
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def pathnames
      paths.map { |path| Pathname.new(path) }
    end

    def engine_extensions
      @trail.extensions
    end

    def files
      files = Set.new
      pathnames.each do |base_pathname|
        Dir["#{base_pathname}/**/*"].each do |filename|
          logical_path = Pathname.new(filename).relative_path_from(base_pathname)
          files << EnginePathname.new(logical_path, engines).without_engine_extensions
        end
      end
      files
    end

    def resolve(logical_path, options = {})
      if block_given?
        @trail.find(logical_path.to_s, logical_index_path(logical_path), options) do |path|
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
      if @assets.key?(logical_path.to_s)
        return @assets[logical_path.to_s]
      end

      if fingerprint = Utils.path_fingerprint(logical_path)
        pathname = resolve(logical_path.to_s.sub("-#{fingerprint}", ''))
      else
        pathname = resolve(logical_path)
      end
    rescue FileNotFound
      nil
    else
      if engines.concatenatable?(pathname)
        logger.info "[Sprockets] #{logical_path} building"
        asset = ConcatenatedAsset.new(self, pathname, engines)
      else
        asset = StaticAsset.new(pathname, engines)
      end

      if fingerprint && fingerprint != asset.digest
        logger.error "[Sprockets] #{logical_path} #{fingerprint} nonexistent"
        asset = nil
      end

      @assets[logical_path.to_s] = asset
      asset
    end

    private
      def logical_index_path(logical_path)
        pathname = Pathname.new(logical_path)
        engine_pathname = EnginePathname.new(logical_path, engines)

        if engine_pathname.basename_without_extensions.to_s == 'index'
          logical_path
        else
          basename = "#{engine_pathname.basename_without_extensions}/index#{engine_pathname.extensions.join}"
          pathname.dirname.to_s == '.' ? basename : pathname.dirname.join(basename).to_s
        end
      end
  end
end
