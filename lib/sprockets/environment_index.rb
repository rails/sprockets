require 'sprockets/path_index'
require 'sprockets/pathname'
require 'sprockets/server'
require 'sprockets/static_index'

module Sprockets
  class EnvironmentIndex
    include Server

    attr_reader :logger, :context, :css_compressor, :js_compressor

    def initialize(environment, trail, static_root)
      @logger         = environment.logger
      @context        = environment.context
      @css_compressor = environment.css_compressor
      @js_compressor  = environment.js_compressor

      @path_index   = PathIndex.new(self, trail)
      @static_index = StaticIndex.new(static_root)
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
            filename = @static_index.root.join(logical_path.with_fingerprint(asset.digest))

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
