require 'tilt'

module Sprockets
  # Tilt engine class for the Eco compiler. Depends on the `eco` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-eco
  #   https://github.com/sstephenson/eco
  #
  class EcoTemplate < Tilt::Template
    # Eco templates always produced compiled JS. We can set Tilt's
    # default mime type hint.
    def self.default_mime_type
      'application/javascript'
    end

    # Autoload eco library. If the library isn't loaded, Tilt will produce
    # a thread safetly warning. If you intend to use `.eco` files, you
    # should explicitly require it.
    def initialize_engine
      require_template_library 'eco'
    end

    def prepare
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
