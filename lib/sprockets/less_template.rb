require 'tilt'

module Sprockets
  class LessTemplate < Tilt::Template
    self.default_mime_type = 'text/css'

    def self.engine_initialized?
      defined? ::Less
    end

    def initialize_engine
      require_template_library 'less'
    end

    def prepare
      if ::Less.const_defined? :Engine
        @engine = ::Less::Engine.new(data)
      else
        parser  = ::Less::Parser.new(options.merge :filename => eval_file, :line => line)
        @engine = parser.parse(data)
      end
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_css(options)
    end
  end
end
