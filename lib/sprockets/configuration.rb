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
      @preprocessors     = deep_copy_hash(parent.preprocessors)
      @postprocessors    = deep_copy_hash(parent.postprocessors)
      @bundle_processors = deep_copy_hash(parent.bundle_processors)
      @compressors       = deep_copy_hash(parent.compressors)
    end

    private
      def mutate_config(sym)
        obj = self.instance_variable_get("@#{sym}").dup
        yield obj
        self.instance_variable_set("@#{sym}", obj.freeze)
      end

      def deep_copy_hash(hash)
        initial = Hash.new { |h, k| h[k] = [] }
        hash.each_with_object(initial) { |(k, a),h| h[k] = a.dup }
      end
  end
end
