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
      digest = ::Digest::SHA1.new
      queue = [obj]

      while queue.length > 0
        obj = queue.shift
        case obj
        when String, Symbol, Integer
          digest.update obj.class.name
          digest.update obj.to_s
        when TrueClass, FalseClass, NilClass
          digest.update obj.class.name
        when Array
          digest.update obj.class.name
          obj.each do |e|
            queue << e
          end
        when Hash
          digest.update obj.class.name
          obj.sort.each do |k, v|
            queue << k
            queue << v
          end
        else
          raise TypeError, "can't convert #{obj.inspect} into String"
        end
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
