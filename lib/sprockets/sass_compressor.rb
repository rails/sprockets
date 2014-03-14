module Sprockets
  class SassCompressor
    def self.call(input)
      require 'sass' unless defined? ::Sass::Engine

      data = input[:data]

      ::Sass::Engine.new(data, {
        :syntax => :scss,
        :cache => false,
        :read_cache => false,
        :style => :compressed
      }).render
    end
  end
end
