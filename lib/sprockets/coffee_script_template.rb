module Sprockets
  class CoffeeScriptTemplate < Template
    self.default_mime_type = 'application/javascript'

    def self.engine_initialized?
      defined? ::CoffeeScript
    end

    def initialize_engine
      require_template_library 'coffee_script'
    end

    def prepare
    end

    def evaluate(scope, locals, &block)
      @output ||= CoffeeScript.compile(data, options)
    end
  end
end
