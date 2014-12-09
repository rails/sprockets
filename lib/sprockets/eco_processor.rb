require 'eco'

module Sprockets
  # Processor engine class for the Eco compiler. Depends on the `eco` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-eco
  #   https://github.com/sstephenson/eco
  #
  module EcoProcessor
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
      key  = [self.name, ::Eco::Source::VERSION, VERSION, data]
      input[:cache].fetch(key) do
        ::Eco.compile(data)
      end
    end
  end
end
