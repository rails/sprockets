require 'tilt'

module Sprockets
  class EcoTemplate < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def initialize_engine
      require_template_library 'eco'
    end

    def prepare
    end

    def evaluate(scope, locals, &block)
      Eco.compile(data)
    end
  end
end
