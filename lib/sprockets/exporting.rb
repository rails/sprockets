require 'sprockets/engines'
require 'sprockets/file_reader'
require 'sprockets/legacy_proc_processor'
require 'sprockets/legacy_tilt_processor'
require 'sprockets/mime'
require 'sprockets/processor_utils'
require 'sprockets/uri_utils'
require 'sprockets/utils'

module Sprockets
  # `Exporting` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Exporting
    include ProcessorUtils, URIUtils, Utils

    # Exporters are ran on the assets:precompile task
    def exporters
      config[:exporters]
    end

    # Registers a new Exporter `klass` for `mime_type`.
    #
    #     register_preprocessor '*/*', Sprockets::GzipExporter
    #
    def register_exporter(mime_types, proc = nil, &block)
      proc ||= block

      if mime_types.is_a? String
        mime_types = [mime_types]
      end
      mime_types.each do |mime_type|
        self.config = hash_reassoc(config, :exporters, mime_type) do |_exporters|
          _exporters << proc
        end
      end
    end
  end
end
