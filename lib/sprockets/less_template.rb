require 'less'

module Sprockets
  module LessTemplate
    def self.call(input)
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
