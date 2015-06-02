require 'sprockets/autoload'
require 'sprockets/digest_utils'
require 'sprockets/source_map_utils'

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

    # Public: Return singleton instance with default options.
    #
    # Returns UglifierCompressor object.
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
      # Feature detect Uglifier 2.0 option support
      if Autoload::Uglifier::DEFAULTS[:copyright]
        # Uglifier < 2.x
        options[:copyright] ||= false
      else
        # Uglifier >= 2.x
        options[:copyright] ||= :none
      end

      @uglifier = Autoload::Uglifier.new(options)
      @cache_key = "#{self.class.name}:#{Autoload::Uglifier::VERSION}:#{VERSION}:#{DigestUtils.digest(options)}".freeze
    end

    def call(input)
      js, map = @uglifier.compile_with_map(input[:data])

      map = SourceMapUtils.combine_source_maps(
        input[:metadata][:map],
        SourceMapUtils.decode_json_source_map(map)["mappings"]
      )

      { data: js, map: map }
    end
  end
end
