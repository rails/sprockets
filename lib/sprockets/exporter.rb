module Sprockets
  class Exporter
    def initialize(environment, asset, source, directory, logger, mtime)
      @environment = environment
      @asset = asset
      @source = source
      @directory = directory
      @logger = logger
      @mtime = mtime
    end

    def write(extension = nil)
      if extension
        target = extension[0] == '.' ? "#{source}#{extension}" : extension
      else
        target = source
      end

      if File.exist?(target)
        logger.debug "Skipping #{target}, already exists"
      else
        logger.info "Exporting #{target}"
        begin
          yield target
          logger.warn "#{target} was not exported" if !File.exist?(target)
        rescue => e
          logger.error "#{e} while exporting #{target}"
          raise e
        end
      end
    end

    attr_reader :environment
    attr_reader :asset
    attr_reader :source
    attr_reader :directory
    attr_reader :logger
    attr_reader :mtime
  end
end
