module Sprockets
  class CoffeeScriptTemplate
    def self.call(input)
      require 'coffee_script' unless defined? ::CoffeeScript
      CoffeeScript.compile(input[:data])
    end
  end
end
