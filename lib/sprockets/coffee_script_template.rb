module Sprockets
  class CoffeeScriptTemplate < Template
    def render(context)
      require 'coffee_script' unless defined? ::CoffeeScript
      @output ||= CoffeeScript.compile(data)
    end
  end
end
