require 'sprockets/http_utils'
require 'sprockets/processor_utils'
require 'sprockets/utils'

module Sprockets
  module Archiving
    include Utils

    def archivers
      config[:archivers]
    end

    # Public: Register archiver, it has to respond to 3 methods
    # type can be any symbol
    #
    # register_archiver :gzip, Utils::Zlib 
    #
    # will register Zlib compression for text file, 
    # we dont use myme_types here, because different mime_type 
    # can be compressed by one archiver (text/stylesheets, text/javascript, etc)
    def register_archiver type, archiver
      if archiver.is_a?( Class )
        klass = archiver
      else
        raise(Error, "archiver is'n a class: #{archiver}")
      end

      self.config = hash_reassoc(config, :archivers) do |archivers|
        archivers[type] = klass
        archivers
      end
    end

    def unregister_archiver type
      self.config = hash_reassoc(config, :archivers) do |archivers|
        archivers.delete(type)
        archivers
      end
    end

    # Public: Checks if archiver is enabled.
    def archiver_enabled? type
      archiver = archivers[type]
      if archiver.nil?
        false
      else
        if type == :gzip
          config[:gzip_enabled] ? true : false
        else
          true
        end
      end
    end

    # Public: Checks if archiver is disabled.
    def skip_archiver? type
      !archiver_enabled?
    end

    # Public: Checks if Gzip is enabled.
    def gzip?
      warn "gzip? method is deprecated. Use archiver_enabled?(:gzip) to check if gzip is enabled"
      config[:gzip_enabled]
    end

    # Public: Checks if Gzip is disabled.
    def skip_gzip?
      warn "skip_gzip? method is deprecated. Use skip_archiver?(:gzip) to check if gzip is disabled"
      !gzip?
    end

    # Public: Enable or disable the creation of Gzip files.
    #
    # Defaults to true.
    #
    #     environment.gzip = false
    #
    def gzip=(gzip)
      self.config = config.merge(gzip_enabled: gzip).freeze
    end

    # Public: Get list of archivers which is active
    def active_archivers
      result = []
      archivers.each do |sym, archiver|
        result << archiver if archiver_enabled?( sym )
      end
      result
    end
  end
end