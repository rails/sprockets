require 'sass'

module Sprockets
  class SassCompressor
    def self.compress(css)
      new.compress(css)
    end

    def compress(css)
      Sass::Engine.new(css, {
        :syntax => :scss,
        :cache => false,
        :read_cache => false,
        :style => :compressed
      }).render
    end
  end
end
