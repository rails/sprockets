require 'eco'

module Sprockets
  # Template engine class for the Eco compiler. Depends on the `eco` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-eco
  #   https://github.com/sstephenson/eco
  #
  module EcoTemplate
    VERSION = '1'

    # Compile template data with Eco compiler.
    #
    # Returns a JS function definition String. The result should be
    # assigned to a JS variable.
    #
    #     # => "function(...) {...}"
    #
    def self.call(input)
      data = input[:data]
      key  = ['EcoTemplate', ::Eco::Source::VERSION, VERSION, data]
      input[:cache].fetch(key) do
        ::Eco.compile(data)
      end
    end
  end
end
