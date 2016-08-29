require 'sprockets/exporter'

module Sprockets
  class FileExporter < Exporter
    def call
      write do |target|
        asset.write_to target
      end
    end
  end
end
