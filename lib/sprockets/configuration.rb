require 'sprockets/compressing'
require 'sprockets/engines'
require 'sprockets/mime'
require 'sprockets/paths'
require 'sprockets/processing'

module Sprockets
  module Configuration
    include Paths, Mime, Engines, Processing, Compressing

    def initialize_configuration(parent)
      @paths             = parent.paths
      @mime_types        = parent.mime_types
      @mime_exts         = parent.mime_exts
      @engines           = parent.engines
      @engine_extensions = parent.engine_extensions
      @preprocessors     = parent.preprocessors
      @postprocessors    = parent.postprocessors
      @bundle_processors = parent.bundle_processors
      @compressors       = parent.compressors
    end

    private
      def mutate_config(sym)
        obj = self.instance_variable_get("@#{sym}").dup
        yield obj
        self.instance_variable_set("@#{sym}", obj.freeze)
      end

      def mutate_hash_config(sym, key)
        mutate_config(sym) do |hash|
          obj = hash[key].dup
          yield obj
          hash[key] = obj.freeze
        end
      end
  end
end
