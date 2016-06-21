require 'sprockets/erb_processor'

module Sprockets
  # Deprecated
  class ERBTemplate < ERBProcessor
    def call(*args)
      Sprockets::Deprecation.new.warn "ERBTemplate is deprecated please use ERBProcessor instead"
      super
    end
  end
end
