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

    # Internal: Halt when recursive circular call is detected.
    #
    # path - String path to ensure is not required multiple times.
    #
    # Raises CircularDependencyError if cycle is detected.
    def prevent_circular_calls(path)
      calls = Thread.current[:sprockets_circular_calls] ||= []
      if calls.include?(path)
        raise CircularDependencyError, "#{path} has already been required"
      end
      calls << path
      yield
    ensure
      calls.pop
      Thread.current[:sprockets_circular_calls] = nil if calls.empty?
    end

    def ms_since(start_time)
      secs = Time.now.to_f - start_time.to_f
      (secs * 1000).to_i
    end
  end
end
