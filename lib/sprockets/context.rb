require 'sprockets/engine_pathname'
require 'sprockets/errors'
require 'pathname'

#### Sprockets::Context
#
# The context class keeps track of an environment, basepath, and the logical path for a pathname
# TODO Fill in with better explanation
module Sprockets
  class Context
    attr_reader :concatenation, :pathname

    def initialize(concatenation, pathname)
      @concatenation = concatenation
      @pathname      = pathname
    end

    def environment
      concatenation.environment
    end

    def root_path
      environment.paths.detect { |path| pathname.to_s[path] }
    end

    def logical_path
      if pathname && root_path
        pathname.to_s[%r{^#{root_path}\/([^.]+)}, 1]
      end
    end

    def content_type
      EnginePathname.new(pathname, environment.engines).content_type
    end

    def resolve(path, options = {}, &block)
      pathname        = Pathname.new(path)
      engine_pathname = EnginePathname.new(pathname, environment.engines)

      if pathname.absolute?
        pathname

      elsif content_type = options[:content_type]
        content_type = self.content_type if content_type == :self

        if engine_pathname.format_extension
          if content_type != engine_pathname.content_type
            expected_extension = EnginePathname.extension_for(content_type)
            raise ContentTypeMismatch, "#{path} is " +
              "'#{engine_pathname.format_extension}', not '#{expected_extension}'"
          end
        end

        resolve(path) do |candidate|
          engine_pathname = EnginePathname.new(candidate, environment.engines)

          if self.content_type == engine_pathname.content_type
            return candidate
          end
        end

        raise FileNotFound, "couldn't find file '#{path}'"
      else
        environment.resolve(path, :base_path => self.pathname.dirname, &block)
      end
    end

    def depend_on(path)
      concatenation.depend_on(resolve(path))
    end

    def evaluate(filename, options = {})
      pathname        = resolve(filename)
      engine_pathname = EnginePathname.new(pathname, environment.engines)

      data     = options[:data] || pathname.read
      engines  = options[:engines] || environment.engines.pre_processors +
                          engine_pathname.engines.reverse +
                          environment.engines.post_processors

      engines.inject(data) do |result, engine|
        template = engine.new(pathname.to_s) { result }
        template.render(self, {})
      end
    end
  end
end
