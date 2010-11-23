require "hike"

module Sprockets
  class Environment
    class << self
      attr_accessor :engine_extensions
    end

    self.engine_extensions = %w( coffee erb less sass scss str )

    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      @trail.extensions.replace(self.class.engine_extensions)
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def resolve(logical_path)
      if path = @trail.find(logical_path)
        Pathname.new(path)
      else
        raise FileNotFound, "couldn't find file '#{logical_path}'"
      end
    end

    def find_asset(logical_path)
      pathname = resolve(logical_path)

      if concatenatable?(pathname.format_extension)
        ConcatenatedAsset.new(self, pathname)
      else
        StaticAsset.new(self, pathname)
      end
    end

    alias_method :[], :find_asset

    def concatenatable?(format_extension)
      %w( .js .css ).include?(format_extension)
    end
  end
end
