module Sprockets
  class GzipExporter
    def self.call(env, asset, target, dir, logger, wait)
      return if env.skip_gzip?
      gzip = Utils::Gzip.new(asset)
      return if gzip.cannot_compress?(env.mime_types)

      if File.exist?("#{target}.gz")
        logger.debug "Skipping #{target}.gz, already exists"
        return
      else
        logger.info "Writing #{target}.gz"
        return Concurrent::Future.execute do
          wait.call
          gzip.compress(target)
        end
      end
    end
  end
end
