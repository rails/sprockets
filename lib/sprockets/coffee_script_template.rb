module Sprockets
  class CoffeeScriptTemplate < Template
    self.default_mime_type = 'application/javascript'

    def self.engine_initialized?
      defined? ::CoffeeScript
    end

    def initialize_engine
      require 'coffee_script'
    end

    def render(context)
      @output ||= CoffeeScript.compile(data)
    end
  end
end
