module Sprockets
  class Context
    attr_reader :pathname

    def initialize(environment, concatenation, pathname)
      @_environment   = environment
      @_concatenation = concatenation
      @pathname       = pathname
    end

    def paths
      @_environment.paths
    end

    def logical_path
      if pathname && (root_path = paths.detect { |path| pathname.to_s[path] })
        pathname.to_s[%r{^#{root_path}\/([^.]+)}, 1]
      end
    end

    def resolve(path, &block)
      @_environment.resolve(path, :base_path => pathname.dirname, &block)
    end

    def depend(path)
      @_concatenation.depend(expand_path(path))
    end

    # TODO: should not be shaddowing Kernal::require
    def require(path)
      @_concatenation.require(expand_path(path))
    end

    def process(path)
      @_concatenation.process(expand_path(path))
    end

    private
      def expand_path(path)
        pathname = Pathname.new(path)
        pathname.absolute? ? pathname : resolve(pathname)
      end
  end
end
