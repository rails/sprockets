require 'digest/sha1'

module Sprockets
  # `Utils`, we didn't know where else to put it!
  module Utils
    extend self

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
    # obj - A JSON serializable object.
    #
    # Returns a String SHA1 digest of the object.
    def hexdigest(obj)
      buf   = ""
      queue = [obj]

      while queue.length > 0
        obj = queue.shift
        klass = obj.class

        if klass == String
          buf << 'String'
          buf << obj
        elsif klass == Symbol
          buf << 'Symbol'
          buf << obj.to_s
        elsif klass == Fixnum
          buf << 'Fixnum'
          buf << obj.to_s
        elsif klass == TrueClass
          buf << 'TrueClass'
        elsif klass == FalseClass
          buf << 'FalseClass'
        elsif klass == NilClass
          buf << 'NilClass'
        elsif klass == Array
          buf << 'Array'
          queue.concat(obj)
        elsif klass == Hash
          buf << 'Hash'
          queue.concat(obj.sort)
        else
          raise TypeError, "couldn't digest #{klass}"
        end
      end

      ::Digest::SHA1.hexdigest(buf)
    end

    def benchmark_start
      Time.now.to_f
    end

    def benchmark_end(start_time)
      ((Time.now.to_f - start_time) * 1000).to_i
    end
  end
end
