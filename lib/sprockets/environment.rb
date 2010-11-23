require "hike"

module Sprockets
  class Environment
    class << self
      attr_accessor :extensions
    end

    self.extensions = %w( coffee erb less sass scss str )

    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      @trail.extensions.replace(self.class.extensions)
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def find_asset(logical_path)
      ConcatenatedAsset.require(self, find_source_file(logical_path))
    end

    alias_method :[], :find_asset

    def find_source_file(logical_path)
      if path = @trail.find(logical_path)
        SourceFile.new(path)
      else
        raise FileNotFound,
          "couldn't find source file '#{logical_path}'"
      end
    end
  end
end
