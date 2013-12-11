require 'tilt'

module Sprockets
  class StringTemplate < Tilt::Template
    def prepare
      hash = "TILT#{data.hash.abs}"
      @code = "<<#{hash}.chomp\n#{data}\n#{hash}"
    end

    def precompiled_template(locals)
      @code
    end

    def precompiled(locals)
      source, offset = super
      [source, offset + 1]
    end
  end
end
