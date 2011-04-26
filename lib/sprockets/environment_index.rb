require 'sprockets/path_index'
require 'sprockets/server'
require 'sprockets/static_index'
require 'pathname'

module Sprockets
  class EnvironmentIndex
    include Server

    attr_reader :logger, :context, :engines, :css_compressor, :js_compressor

    def initialize(environment, trail, static_root)
      @logger         = environment.logger
      @context        = environment.context
      @engines        = environment.engines.dup
      @css_compressor = environment.css_compressor
      @js_compressor  = environment.js_compressor

      @path_index   = PathIndex.new(self, trail)
      @static_index = StaticIndex.new(static_root, engines)
    end

    def root
      @path_index.root
    end

    def paths
      @path_index.paths
    end

    def engine_extensions
      @path_index.engine_extensions
    end

    def static_root
      @static_index.root
    end

    def index
      self
    end

    def precompile(*paths)
      raise "missing static root" unless @static_index.root

      paths.each do |path|
        @path_index.files.each do |logical_path|
          if path.is_a?(Regexp)
            next unless path.match(logical_path.to_s)
          else
            next unless logical_path.fnmatch(path.to_s)
          end

          if asset = @path_index.find_asset(logical_path)
            digest_path = Utils.path_with_fingerprint(logical_path, asset.digest)
            filename = @static_index.root.join(digest_path)

            FileUtils.mkdir_p filename.dirname

            filename.open('w') do |f|
              f.write asset.to_s
            end
          end
        end
      end
    end

    def resolve(*args, &block)
      @path_index.resolve(*args, &block)
    end

    def find_asset(logical_path)
      logical_path = Pathname.new(logical_path)
      @static_index.find_asset(logical_path) || @path_index.find_asset(logical_path)
    end
    alias_method :[], :find_asset
  end
end
