# frozen_string_literal: true
module Sprockets
  module Utils
    class Gzip
      # Private: Generates a gzipped file based off of reference asset.
      #
      #     ZlibArchiver.call(file, source)
      #
      # Compresses a given `source` using stdlib Zlib algorithm
      # writes contents to the `file` passed in.
      module ZlibArchiver
        def self.call(file, source)
          gz = Zlib::GzipWriter.new(file, Zlib::BEST_COMPRESSION)
          gz.mtime = 1 # for reproducibility
          gz.write(source)
          gz.close

          File.utime(1, 1, file.path)
        end
      end

      # Private: Generates a gzipped file based off of reference asset.
      #
      #     ZopfliArchiver.call(file, source)
      #
      # Compresses a given `source` using the zopfli gem
      # writes contents to the `file` passed in.
      module ZopfliArchiver
        def self.call(file, source)
          compressed_source = Autoload::Zopfli.deflate(source, format: :gzip, mtime: 1)
          file.write(compressed_source)
          file.close

          nil
        end
      end

      attr_reader :content_type, :source, :charset, :archiver

      # Private: Generates a gzipped file based off of reference file.
      def initialize(asset, archiver: ZlibArchiver)
        @content_type  = asset.content_type
        @source        = asset.source
        @charset       = asset.charset
        @archiver      = archiver
      end

      # What non-text mime types should we compress? This list comes from:
      # https://www.fastly.com/blog/new-gzip-settings-and-deciding-what-compress
      COMPRESSABLE_MIME_TYPES = {
        "application/vnd.ms-fontobject" => true,
        "application/x-font-opentype" => true,
        "application/x-font-ttf" => true,
        "image/x-icon" => true,
        "image/svg+xml" => true
      }

      # Private: Returns whether or not an asset can be compressed.
      #
      # We want to compress any file that is text based.
      # You do not want to compress binary
      # files as they may already be compressed and running them
      # through a compression algorithm would make them larger.
      #
      # Return Boolean.
      def can_compress?
        # The "charset" of a mime type is present if the value is
        # encoded text. We can check this value to see if the asset
        # can be compressed.
        #
        # We also check against our list of non-text compressible mime types
        @charset || COMPRESSABLE_MIME_TYPES.include?(@content_type)
      end

      # Private: Opposite of `can_compress?`.
      #
      # Returns Boolean.
      def cannot_compress?
        !can_compress?
      end

      # Private: Generates a gzipped file based off of reference asset.
      #
      # Compresses the target asset's contents and puts it into a file with
      # the same name plus a `.gz` extension in the same folder as the original.
      # Does not modify the target asset.
      #
      # Returns nothing.
      def compress(file, target)
        archiver.call(file, source)

        nil
      end
    end
  end
end
