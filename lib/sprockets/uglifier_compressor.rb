require 'sprockets/autoload'

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
    VERSION = '1'

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

      @cache_key = [
        self.class.name,
        Autoload::Uglifier::VERSION,
        VERSION,
        options
      ].freeze
    end

    def call(input)
      data = input[:data]
      input[:cache].fetch(@cache_key + [data]) do
        @uglifier.compile(data)
      end
    end
  end
end
