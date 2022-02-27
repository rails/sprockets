# frozen_string_literal: true
require 'sprockets/autoload'
require 'sprockets/digest_utils'
require 'sprockets/source_map_utils'

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
    VERSION = '2'

    # Public: Return singleton instance with default options.
    #
    # Returns SassCompressor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def self.cache_key
      instance.cache_key
    end

    attr_reader :cache_key

    def initialize(options = {})
      @options = {
        syntax: :css,
        style: :compressed,
        source_map: true
      }.merge(options).freeze
      @cache_key = "#{self.class.name}:#{Autoload::Sass::Embedded::VERSION}:#{VERSION}:#{DigestUtils.digest(options)}".freeze
    end

    def call(input)
      result = Autoload::Sass.compile_string(
        input[:data],
        **@options.merge(url: URIUtils.build_asset_uri(input[:filename]))
      )

      css = result.css

      map = SourceMapUtils.format_source_map(JSON.parse(result.source_map), input)
      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)

      { data: css, map: map }
    end
  end
end
