require 'sprockets/exporter'
require 'sprockets/utils/gzip'

module Sprockets
  class GzipExporter < Exporter
    def call
      return if environment.skip_gzip?
      gzip = Utils::Gzip.new(asset)
      return if gzip.cannot_compress?(environment.mime_types)

      write '.gz' do
        gzip.compress(source)
      end
    end
  end
end
