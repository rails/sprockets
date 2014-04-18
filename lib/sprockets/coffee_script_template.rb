require 'coffee_script'
require 'json'

module Sprockets
  # Template engine class for the CoffeeScript compiler.
  # Depends on the `coffee-script` and `coffee-script-source` gems.
  #
  # For more infomation see:
  #
  #   https://github.com/josh/ruby-coffee-script
  #
  module CoffeeScriptTemplate
    VERSION = '1'

    def self.call(input)
      data = input[:data]
      key  = ['CoffeeScriptTemplate', ::CoffeeScript::Source.version, VERSION, data]
      input[:cache].fetch(key) do
        ::CoffeeScript.compile(data)
      end
    end
  end
end
