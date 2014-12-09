require 'ejs'

module Sprockets
  # Processor engine class for the EJS compiler. Depends on the `ejs` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-ejs
  #
  module EjsProcessor
    VERSION = '1'

    # Compile template data with EJS compiler.
    #
    # Returns a JS function definition String. The result should be
    # assigned to a JS variable.
    #
    #     # => "function(obj){...}"
    #
    def self.call(input)
      data = input[:data]
      key  = [self.name, VERSION, data]
      input[:cache].fetch(key) do
        ::EJS.compile(data)
      end
    end
  end
end
