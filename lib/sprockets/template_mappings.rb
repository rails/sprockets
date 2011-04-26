require 'tilt'

module Sprockets
  module TemplateMappings
    extend self

    ENGINES = Engines.new

    def register(*args)
      ENGINES.register(*args)
    end

    def lookup_engine(*args)
      ENGINES.lookup_engine(*args)
    end
  end
end
