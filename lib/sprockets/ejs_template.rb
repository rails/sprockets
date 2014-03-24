require 'ejs'

module Sprockets
  # Template engine class for the EJS compiler. Depends on the `ejs` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-ejs
  #
  module EjsTemplate
    # Compile template data with EJS compiler.
    #
    # Returns a JS function definition String. The result should be
    # assigned to a JS variable.
    #
    #     # => "function(obj){...}"
    #
    def self.call(input)
      ::EJS.compile(input[:data])
    end
  end
end
