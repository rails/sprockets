module Sprockets
  class CoffeeScriptTemplate < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def initialize_engine
      require_template_library 'coffee_script'
    end

    def prepare
    end

    def evaluate(scope, locals, &block)
      @output ||= CoffeeScript.compile(data, :bare => false)
    end
  end
end
