module Sprockets
  module LessTemplate
    def self.call(input)
      require 'less' unless defined? ::Less

      if ::Less.const_defined? :Engine
        engine = ::Less::Engine.new(input[:data])
      else
        parser = ::Less::Parser.new(:filename => input[:filename])
        engine = parser.parse(input[:data])
      end

      engine.to_css
    end
  end
end
