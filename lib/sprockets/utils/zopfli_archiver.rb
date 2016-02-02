require 'sprockets/autoload'

module Sprockets
  module Utils
    class ZopfliArchiver

      # Private:
      # Compress the target source to file
      #
      # Returns nothing.
      def self.call(file, source, mtime)
        file.write Autoload::Zopfli.deflate source, format: :gzip, mtime: mtime
        file.close

        nil
      end

    end
  end
end
