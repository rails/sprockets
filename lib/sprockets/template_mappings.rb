require 'tilt'

module Sprockets
  module TemplateMappings
    extend self

    MAPPINGS = {}

    def register(ext, klass)
      ext = ext.to_s.sub(/^\./, '').downcase
      MAPPINGS[ext] = klass
    end

    def lookup_engine(ext)
      ext = ext.to_s.sub(/^\./, '').downcase
      MAPPINGS[ext] || Tilt[ext]
    end
  end
end
