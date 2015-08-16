module Sprockets
 # Internal: used to "expand" and "compress" values for storage
  class URITar
    attr_reader :scheme, :root, :path

    # Internal: Initialize object for compression or expansion
    #
    # uri - A String containing URI that may or may not contain the scheme
    # env - The current "environment" that assets are being loaded into.
    def initialize(uri, env)
      @root = env.root
      @env  = env
      if uri.include?("://".freeze)
        uri_array = uri.split("://".freeze)
        @scheme   = uri_array.shift
        @scheme   << "://".freeze
        @path     = uri_array.join("".freeze)
      else
        @scheme = "".freeze
        @path   = uri
      end
    end

    # Internal: Converts full uri to a "compressed" uri
    #
    # If a uri is inside of an environment's root it will
    # be shortened to be a relative path.
    #
    # If a uri is outside of the environment's root the original
    # uri will be returned.
    #
    # Returns String
    def compress
      scheme + compressed_path
    end

    # Internal: Convert a "compressed" uri to an absolute path
    #
    # If a uri is inside of the environment's root it will not
    # start with a slash for example:
    #
    #   file://this/is/a/relative/path
    #
    # If a uri is outside the root, it will start with a slash:
    #
    #   file:///This/is/an/absolute/path
    #
    # Returns String
    def expand
      if path.start_with?("/".freeze)
        # Stored path was absolute, don't add root
        scheme + path
      else
        # Stored path was relative, add root
        scheme + File.join(root, path)
      end
    end

    # Internal: Returns "compressed" path
    #
    # If the input uri is relative to the environment root
    # it will return a path relative to the environment root.
    # Otherwise an absolute path will be returned.
    #
    # Only path information is returned, and not scheme.
    #
    # Returns String
    def compressed_path
      if compressed_path = @env.split_subpath(root, path)
        compressed_path
      else
        path
      end
    end
  end
end
