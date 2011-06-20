require 'tilt'

module Sprockets
  # Tilt engine class for the EJS compiler. Depends on the `ejs` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/sstephenson/ruby-ejs
  #
  class EjsTemplate < Tilt::Template
    # EJS templates always produced compiled JS. We can set Tilt's
    # default mime type hint.
    def self.default_mime_type
      'application/javascript'
    end

    # Autoload ejs library. If the library isn't loaded, Tilt will produce
    # a thread safetly warning. If you intend to use `.ejs` files, you
    # should explicitly require it.
    def initialize_engine
      require_template_library 'ejs'
    end

    def prepare
    end

    # Compile template data with EJS compiler.
    #
    # Returns a JS function definition String. The result should be
    # assigned to a JS variable.
    #
    #     # => "function(obj){...}"
    #
    def evaluate(scope, locals, &block)
      EJS.compile(data)
    end
  end
end
