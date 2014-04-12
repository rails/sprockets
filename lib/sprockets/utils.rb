require 'digest/sha1'
require 'pathname'

module Sprockets
  # `Utils`, we didn't know where else to put it!
  module Utils
    extend self

    # Define UTF-8 BOM pattern matcher.
    # Avoid using a Regexp literal because it inheirts the files
    # encoding and we want to avoid syntax errors in other interpreters.
    UTF8_BOM_PATTERN = Regexp.new("\\A\uFEFF".encode('utf-8'))

    def read_unicode(filename, external_encoding = Encoding.default_external)
      Pathname.new(filename).open("r:#{external_encoding}") do |f|
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

    # Prepends a leading "." to an extension if its missing.
    #
    #     normalize_extension("js")
    #     # => ".js"
    #
    #     normalize_extension(".css")
    #     # => ".css"
    #
    def normalize_extension(extension)
      extension = extension.to_s
      if extension[/^\./]
        extension
      else
        ".#{extension}"
      end
    end

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # obj    - A JSON serializable object.
    # digest - Digest instance to modify
    #
    # Returns a String SHA1 digest of the object.
    def hexdigest(obj, digest = ::Digest::SHA1.new)
      case obj
      when String, Symbol, Integer
        digest.update "#{obj.class}"
        digest.update "#{obj}"
      when TrueClass, FalseClass, NilClass
        digest.update "#{obj.class}"
      when Array
        digest.update "#{obj.class}"
        obj.each do |e|
          hexdigest(e, digest)
        end
      when Hash
        digest.update "#{obj.class}"
        obj.map { |(k, v)| hexdigest([k, v]) }.sort.each do |e|
          digest.update(e)
        end
      else
        raise TypeError, "can't convert #{obj.inspect} into String"
      end

      digest.hexdigest
    end
  end
end
