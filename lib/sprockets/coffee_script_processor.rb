require 'coffee_script'

module Sprockets
  # Processor engine class for the CoffeeScript compiler.
  # Depends on the `coffee-script` and `coffee-script-source` gems.
  #
  # For more infomation see:
  #
  #   https://github.com/josh/ruby-coffee-script
  #
  module CoffeeScriptProcessor
    VERSION = '1'
    SOURCE_VERSION = ::CoffeeScript::Source.version

    def self.call(input)
      data = input[:data]
      key  = [self.name, SOURCE_VERSION, VERSION, data]
      input[:cache].fetch(key) do
        ::CoffeeScript.compile(data)
      end
    end
  end
end
