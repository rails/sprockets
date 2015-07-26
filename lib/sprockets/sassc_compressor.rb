require 'sprockets/autoload'
require 'sprockets/sassc_importer'
require 'sprockets/sass_compressor'

module Sprockets
  class SasscCompressor < SassCompressor
    def initialize(options = {})
      @options = {
        syntax: :scss,
        style: :compressed,
        importer: SasscImporter,
      }.merge(options).freeze
    end

    def call(input)
      Autoload::SassC::Engine.new(input[:data], @options.merge(filename: 'filename')).render
    end
  end
end
