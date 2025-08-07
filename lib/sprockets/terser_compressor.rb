# frozen_string_literal: true
require 'sprockets/digest_utils'
require 'sprockets/source_map_utils'

module Sprockets
  class TerserCompressor
    VERSION = '1'

    def initialize(options = {})
      @options = options.dup
      @options[:comments] ||= :none
      @options.merge!(::Rails.application.config.assets.terser.to_h) if defined?(::Rails)
      @cache_key = -"#{self.class.name}:#{Autoload::Terser::VERSION}:#{VERSION}:#{DigestUtils.digest(options)}"
      @terser = ::Terser.new(@options)
    end

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

    def call(input)
      input_options = { source_map: { filename: input[:filename] } }

      js, map = @terser.compile_with_map(input[:data], input_options)

      map = SourceMapUtils.format_source_map(JSON.parse(map), input)
      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)

      { data: js, map: map }
    end
  end
end
