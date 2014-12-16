require 'closure-compiler'

module Sprockets
  # Public: Closure Compiler minifier.
  #
  # To accept the default options
  #
  #     environment.register_bundle_processor 'application/javascript',
  #       Sprockets::ClosureCompressor
  #
  # Or to pass options to the Closure::Compiler class.
  #
  #     environment.register_bundle_processor 'application/javascript',
  #       Sprockets::ClosureCompressor.new({ ... })
  #
  class ClosureCompressor
    VERSION = '1'

    # Public: Return singleton instance with default options.
    #
    # Returns ClosureCompressor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def initialize(options = {})
      @compiler = ::Closure::Compiler.new(options)
      @cache_key = [
        self.class.name,
        ::Closure::VERSION,
        ::Closure::COMPILER_VERSION,
        VERSION,
        options
      ].freeze
    end

    def call(input)
      input[:cache].fetch(@cache_key + [input[:data]]) do
        @compiler.compile(input[:data])
      end
    end
  end
end
