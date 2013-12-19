module Sprockets
  class LessTemplate < Template
    self.default_mime_type = 'text/css'

    def self.engine_initialized?
      defined? ::Less
    end

    def initialize_engine
      require 'less'
    end

    def render(context)
      if ::Less.const_defined? :Engine
        engine = ::Less::Engine.new(data)
      else
        parser = ::Less::Parser.new(:filename => file)
        engine = parser.parse(data)
      end

      engine.to_css
    end
  end
end
