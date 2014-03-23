require 'sass'

module Sprockets
  class SassCompressor
    def self.call(input)
      data = input[:data]

      ::Sass::Engine.new(data, {
        syntax: :scss,
        cache: false,
        read_cache: false,
        style: :compressed
      }).render
    end
  end
end
