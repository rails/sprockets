require 'sprockets/engine_pathname'
require 'sprockets/errors'
require 'pathname'

#### Sprockets::Context
#
# The context class keeps track of an environment, basepath, and the logical path for a pathname
# TODO Fill in with better explanation
module Sprockets
  class Context
    attr_reader :environment, :pathname

    def initialize(environment, concatenation, pathname)
      @_concatenation = concatenation
      @environment    = environment
      @pathname       = pathname
    end

    def paths
      environment.paths
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
      EnginePathname.new(pathname, environment.engines).content_type
    end

    def resolve(path, &block)
      environment.resolve(path, :base_path => pathname.dirname, &block)
    end

    def depend(path)
      @_concatenation.depend(_expand_path(path))
    end

    # TODO: should not be shaddowing Kernal::require
    def require(path)
      pathname        = Pathname.new(path)
      engine_pathname = EnginePathname.new(pathname, environment.engines)

      if engine_pathname.format_extension
        if self.content_type != engine_pathname.content_type
          raise ContentTypeMismatch, "#{path} is " +
            "'#{engine_pathname.format_extension}', not '#{EnginePathname.new(self.pathname, environment.engines).format_extension}'"
        end
      end

      if pathname.absolute?
        @_concatenation.require(pathname)
      else
        resolve(path) do |candidate|
          engine_pathname = EnginePathname.new(candidate, environment.engines)

          if self.content_type == engine_pathname.content_type
            @_concatenation.require(candidate)
            return
          end
        end

        raise FileNotFound, "couldn't find file '#{path}'"
      end
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
