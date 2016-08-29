module Sprockets
  # `Exporting` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Exporting
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

    def unregister_exporter(mime_types, exporter = nil)
      unless mime_types.is_a? Array
        if mime_types.is_a? String
          mime_types = [mime_types]
        elsif mime_types < Exporter
          exporter = mime_types
          mime_types = nil
        end
      end

      self.config = hash_reassoc(config, :exporters) do |_exporters|
        _exporters.each do |mime_type, exporters_array|
          next if mime_types && !mime_types.include?(mime_type)
          if exporters_array.include? exporter
            _exporters[mime_type] = exporters_array.dup.delete exporter
          end
        end
      end
    end

    def export_concurrent
      config[:export_concurrent]
    end

    def export_concurrent=(export_concurrent)
      self.config = config.merge(export_concurrent: export_concurrent).freeze
    end

  end
end
