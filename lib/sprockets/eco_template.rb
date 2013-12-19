module Sprockets
  # Template engine class for the Eco compiler. Depends on the `eco` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-eco
  #   https://github.com/sstephenson/eco
  #
  class EcoTemplate < Template
    # Check to see if Eco is loaded
    def self.engine_initialized?
      defined? ::Eco
    end

    # Autoload eco library. If the library isn't loaded, it will produce
    # a thread safetly warning. If you intend to use `.eco` files, you
    # should explicitly require it.
    def initialize_engine
      require 'eco'
    end

    # Compile template data with Eco compiler.
    #
    # Returns a JS function definition String. The result should be
    # assigned to a JS variable.
    #
    #     # => "function(...) {...}"
    #
    def evaluate(scope, locals, &block)
      Eco.compile(data)
    end
  end
end
