require 'json'
require 'sass'

module Sprockets
  # Public: Sass CSS minifier.
  #
  # To accept the default options
  #
  #     environment.register_bundle_processor 'text/css',
  #       Sprockets::SassCompressor
  #
  # Or to pass options to the Sass::Engine class.
  #
  #     environment.register_bundle_processor 'text/css',
  #       Sprockets::SassCompressor.new({ ... })
  #
  class SassCompressor
    VERSION = '1'

    def self.call(*args)
      new.call(*args)
    end

    def initialize(options = {})
      @options = options
      @cache_key = [
        ::Sass::VERSION,
        VERSION,
        JSON.generate(options)
      ]
    end

    def call(input)
      data = input[:data]
      input[:cache].fetch(@cache_key + [data]) do
        options = {
          syntax: :scss,
          cache: false,
          read_cache: false,
          style: :compressed
        }.merge(@options)
        ::Sass::Engine.new(data, options).render
      end
    end
  end
end
