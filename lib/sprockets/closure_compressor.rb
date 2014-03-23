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

    def self.call(*args)
      new.call(*args)
    end

    def initialize(options = {})
      @compiler = Closure::Compiler.new(options)
      @cache_key = [
        Closure::VERSION,
        Closure::COMPILER_VERSION,
        VERSION,
        JSON.generate(options)
      ]
    end

    def call(input)
      input[:cache].fetch(@cache_key + [input[:data]]) do
        @compiler.compile(input[:data])
      end
    end
  end
end
