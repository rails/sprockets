module Sprockets
  module Utils
    if "".respond_to?(:valid_encoding?)
      UTF8_BOM_PATTERN = Regexp.new("\\A\uFEFF".encode('utf-8'))

      def self.read_unicode(pathname)
        pathname.read.tap do |data|
          if !data.valid_encoding?
            raise EncodingError, "Invalid byte sequence"
          elsif data.encoding.name == "UTF-8" && data =~ UTF8_BOM_PATTERN
            data.sub!(UTF8_BOM_PATTERN, "")
          end
        end
      end

    else
      UTF8_BOM_PATTERN  = Regexp.new("\\A\\xEF\\xBB\\xBF")
      UTF16_BOM_PATTERN = Regexp.new("\\A(\\xFE\\xFF|\\xFF\\xFE)")

      def self.read_unicode(pathname)
        pathname.read.tap do |data|
          if data =~ UTF8_BOM_PATTERN
            data.sub!(UTF8_BOM_PATTERN, "")
          elsif data =~ UTF16_BOM_PATTERN
            raise EncodingError, "#{pathname} has a UTF-16 BOM. " +
              "Resave the file as UTF-8 or upgrade to Ruby 1.9."
          end
        end
      end
    end

    def self.normalize_extension(extension)
      extension = extension.to_s
      if extension[/^\./]
        extension
      else
        ".#{extension}"
      end
    end
  end
end
