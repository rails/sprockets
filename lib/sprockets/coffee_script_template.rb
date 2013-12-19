module Sprockets
  class CoffeeScriptTemplate < Template
    self.default_mime_type = 'application/javascript'

    def render(context)
      require 'coffee_script' unless defined? ::CoffeeScript
      @output ||= CoffeeScript.compile(data)
    end
  end
end
