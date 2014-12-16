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
        self.class.name,
        ::Uglifier::VERSION,
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
