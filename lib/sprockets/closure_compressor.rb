require 'closure-compiler'

module Sprockets
  # Public: Closure Compiler minifier.
  #
  # To accept the default options
  #
  #     environment.register_bundle_processor 'text/js',
  #       Sprockets::ClosureCompressor
  #
  # Or to pass options to the Closure::Compiler class.
  #
  #     environment.register_bundle_processor 'text/js',
  #       Sprockets::ClosureCompressor.new({ ... })
  #
  class ClosureCompressor
    def self.call(*args)
      new.call(*args)
    end

    def initialize(*args)
      @compiler = Closure::Compiler.new(*args)
    end

    def call(input)
      @compiler.compile(input[:data])
    end
  end
end
