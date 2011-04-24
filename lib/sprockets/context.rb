module Sprockets
  class Context
    attr_reader :pathname

    def initialize(concatenation, pathname)
      @_concatenation = concatenation
      @_environment   = concatenation.environment
      @pathname       = pathname
    end

    def paths
      @_environment.paths
    end

    def root_path
      paths.detect { |path| pathname.to_s[path] }
    end

    def logical_path
      if pathname && root_path
        pathname.to_s[%r{^#{root_path}\/([^.]+)}, 1]
      end
    end

    def content_type
      pathname.content_type
    end

    def resolve(path, &block)
      @_environment.resolve(path, :base_path => pathname.dirname, &block)
    end

    def depend(path)
      @_concatenation.depend(_expand_path(path))
    end

    # TODO: should not be shaddowing Kernal::require
    def require(path)
      @_concatenation.require(_expand_path(path))
    end

    def process(path)
      @_concatenation.process(_expand_path(path))
    end

    private
      def _expand_path(path)
        pathname = Pathname.new(path)
        pathname.absolute? ? pathname : resolve(pathname)
      end
  end
end
