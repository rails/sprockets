module Sprockets
  class Context
    attr_reader :environment, :asset, :pathname

    def initialize(environment, asset, pathname)
      @environment = environment
      @asset       = asset
      @pathname    = pathname
    end

    def basepath
      environment.paths.detect { |path| pathname.to_s[path] }
    end

    def logical_path
      if pathname && basepath
        pathname.to_s[%r{^#{basepath}\/([^.]+)}, 1]
      end
    end
  end
end
