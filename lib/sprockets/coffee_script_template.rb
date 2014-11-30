require 'coffee_script'

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
    SOURCE_VERSION = ::CoffeeScript::Source.version

    def self.cache_key
      @cache_key ||= [name, SOURCE_VERSION, VERSION].freeze
    end

    def self.call(input)
      data = input[:data]
      input[:cache].fetch(self.cache_key + [data]) do
        ::CoffeeScript.compile(data)
      end
    end
  end
end
