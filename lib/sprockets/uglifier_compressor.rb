require 'json'
require 'uglifier'

module Sprockets
  # Public: Uglifier/Uglify compressor.
  #
  # To accept the default options
  #
  #     environment.register_bundle_processor 'application/javascript',
  #       Sprockets::UglifierCompressor
  #
  # Or to pass options to the Uglifier class.
  #
  #     environment.register_bundle_processor 'application/javascript',
  #       Sprockets::UglifierCompressor.new(comments: :copyright)
  #
  class UglifierCompressor
    VERSION = '2'

    def self.call(*args)
      new.call(*args)
    end

    def initialize(options = {})
      # Feature detect Uglifier 2.0 option support
      if Uglifier::DEFAULTS[:copyright]
        # Uglifier < 2.x
        options[:copyright] ||= false
      else
        # Uglifier >= 2.x
        options[:copyright] ||= :none
      end

      @uglifier = ::Uglifier.new(options)

      @cache_key = [
        'UglifierCompressor',
        ::Uglifier::VERSION,
        VERSION,
        JSON.generate(options)
      ]
    end

    def call(input)
      data = input[:data]

      js, map = input[:cache].fetch(@cache_key + [data]) do
        @uglifier.compile_with_map(data)
      end

      minified = SourceMap::Map.from_json(map)
      original = input[:metadata][:map]
      combined = original | minified

      { data: js,
        map: combined }
    end
  end
end
