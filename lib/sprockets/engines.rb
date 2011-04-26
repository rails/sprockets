require 'tilt'

module Sprockets
  class Engines
    def initialize
      @mappings = Tilt.mappings.dup
    end

    def register(ext, klass)
      ext = ext.to_s.sub(/^\./, '').downcase
      @mappings[ext] = klass
    end

    def lookup_engine(ext)
      ext = ext.to_s.sub(/^\./, '').downcase
      @mappings[ext]
    end
  end
end
