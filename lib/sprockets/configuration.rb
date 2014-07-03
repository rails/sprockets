require 'sprockets/compressing'
require 'sprockets/engines'
require 'sprockets/mime'
require 'sprockets/paths'
require 'sprockets/processing'

module Sprockets
  module Configuration
    include Paths, Mime, Engines, Processing, Compressing

    def initialize_configuration(parent)
      @logger            = parent.logger
      @digest_class      = parent.digest_class
      @context_class     = Class.new(parent.context_class)
      @paths             = parent.paths
      @mime_types        = parent.mime_types
      @mime_exts         = parent.mime_exts
      @encodings         = parent.encodings
      @engines           = parent.engines
      @engine_extensions = parent.engine_extensions
      @preprocessors     = parent.preprocessors
      @postprocessors    = parent.postprocessors
      @bundle_processors = parent.bundle_processors
      @compressors       = parent.compressors
    end

    # Get and set `Logger` instance.
    attr_accessor :logger

    # Returns a `Digest` implementation class.
    #
    # Defaults to `Digest::SHA1`.
    attr_reader :digest_class

    # Assign a `Digest` implementation class. This maybe any Ruby
    # `Digest::` implementation such as `Digest::SHA1` or
    # `Digest::MD5`.
    #
    #     environment.digest_class = Digest::MD5
    #
    def digest_class=(klass)
      @digest_class = klass
    end

    # Deprecated: Get `Context` class.
    #
    # This class maybe mutated and mixed in with custom helpers.
    #
    #     environment.context_class.instance_eval do
    #       include MyHelpers
    #       def asset_url; end
    #     end
    #
    attr_reader :context_class

    private
      def mutate_config(sym)
        obj = yield self.instance_variable_get("@#{sym}").dup
        self.instance_variable_set("@#{sym}", obj.freeze)
      end

      def mutate_hash_config(sym, key)
        mutate_config(sym) do |hash|
          obj = yield hash[key].dup
          hash[key] = obj.freeze
          hash
        end
      end
  end
end
