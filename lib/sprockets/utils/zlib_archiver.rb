module Sprockets
  module Utils
    class ZlibArchiver

      # Private:
      # Compress the target source to file
      #
      # Returns nothing.
      def self.call(file, source, mtime)
        gz = Zlib::GzipWriter.new(file, Zlib::BEST_COMPRESSION)
        gz.mtime = mtime
        gz.write(source)
        gz.close

        nil
      end
    end
  end
end