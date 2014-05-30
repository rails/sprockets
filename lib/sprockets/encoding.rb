module Sprockets
  module Encoding
    extend self

    # Define UTF-8 BOM pattern matcher.
    # Avoid using a Regexp literal because it inheirts the files
    # encoding and we want to avoid syntax errors in other interpreters.
    UTF8_BOM_PATTERN = Regexp.new("\\A\uFEFF".encode('utf-8'))

    # Internal: Read unicode file respecting BOM.
    #
    # Returns String or raises an EncodingError.
    def read_unicode_file(filename, external_encoding = ::Encoding.default_external)
      File.open(filename, "r:#{external_encoding}") do |f|
        f.read.tap do |data|
          # Eager validate the file's encoding. In most cases we
          # expect it to be UTF-8 unless `default_external` is set to
          # something else. An error is usually raised if the file is
          # saved as UTF-16 when we expected UTF-8.
          if !data.valid_encoding?
            raise EncodingError, "#{filename} has a invalid " +
              "#{data.encoding} byte sequence"

            # If the file is UTF-8 and theres a BOM, strip it for safe concatenation.
          elsif data.encoding.name == "UTF-8" && data =~ UTF8_BOM_PATTERN
            data.sub!(UTF8_BOM_PATTERN, "")
          end
        end
      end
    end
  end
end
