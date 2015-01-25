require 'uri'

module Sprockets
  # Internal: Asset URI related parsing utilities. Mixed into Environment.
  #
  # An Asset URI identifies the compiled Asset result. It shares the file:
  # scheme and requires an absolute path.
  #
  # Other query parameters
  #
  # type - String output content type. Otherwise assumed from file extension.
  #        This maybe different than the extension if the asset is transformed
  #        from one content type to another. For an example .coffee -> .js.
  #
  # id - Unique fingerprint of the entire asset and all its metadata. Assets
  #      will only have the same id if they serialize to an identical value.
  #
  # skip_bundle - Boolean if bundle processors should be skipped.
  #
  # encoding - A content encoding such as "gzip" or "deflate". NOT a charset
  #            like "utf-8".
  #
  module URIUtils
    extend self

    # Internal: Parse URI into component parts.
    #
    # uri - String uri
    #
    # Returns Array of components.
    def split_uri(uri)
      URI.split(uri)
    end

    # Internal: Join URI component parts into String.
    #
    # Returns String.
    def join_uri(scheme, userinfo, host, port, registry, path, opaque, query, fragment)
      URI::Generic.new(scheme, userinfo, host, port, registry, path, opaque, query, fragment).to_s
    end

    # Internal: Parse file: URI into component parts.
    #
    # uri - String uri
    #
    # Returns [scheme, host, path, query].
    def split_file_uri(uri)
      scheme, _, host, _, _, path, _, query, _ = URI.split(uri)

      path = URI::Generic::DEFAULT_PARSER.unescape(path)
      path.force_encoding(Encoding::UTF_8)

      # Hack for parsing Windows "file:///C:/Users/IEUser" paths
      path = path.gsub(/^\/([a-zA-Z]:)/, '\1')

      [scheme, host, path, query]
    end

    # Internal: Join file: URI component parts into String.
    #
    # Returns String.
    def join_file_uri(scheme, host, path, query)
      str = "#{scheme}://"
      str << host if host
      path = "/#{path}" unless path.start_with?("/")
      str << URI::Generic::DEFAULT_PARSER.escape(path)
      str << "?#{query}" if query
      str
    end

    # Internal: Check if String is a valid Asset URI.
    #
    # str - Possible String asset URI.
    #
    # Returns true or false.
    def valid_asset_uri?(str)
      # Quick prefix check before attempting a full parse
      str.start_with?("file://") && parse_asset_uri(str) ? true : false
    rescue URI::InvalidURIError
      false
    end

    # Internal: Parse Asset URI.
    #
    # Examples
    #
    #   parse("file:///tmp/js/application.coffee?type=application/javascript")
    #   # => "/tmp/js/application.coffee", {type: "application/javascript"}
    #
    # uri - String asset URI
    #
    # Returns String path and Hash of symbolized parameters.
    def parse_asset_uri(uri)
      scheme, _, path, query = split_file_uri(uri)

      unless scheme == 'file'
        raise URI::InvalidURIError, "expected file:// scheme: #{uri}"
      end

      params = query.to_s.split('&').reduce({}) do |h, p|
        k, v = p.split('=', 2)
        h.merge(k.to_sym => v || true)
      end

      return path, params
    end

    # Internal: Build Asset URI.
    #
    # Examples
    #
    #   build("/tmp/js/application.coffee", type: "application/javascript")
    #   # => "file:///tmp/js/application.coffee?type=application/javascript"
    #
    # path   - String file path
    # params - Hash of optional parameters
    #
    # Returns String URI.
    def build_asset_uri(path, params = {})
      join_file_uri("file", nil, path, encode_uri_query_params(params))
    end

    # Internal: Parse file-digest dependency URI.
    #
    # Examples
    #
    #   parse("file-digest:/tmp/js/application.js")
    #   # => "/tmp/js/application.js"
    #
    # uri - String file-digest URI
    #
    # Returns String path.
    def parse_file_digest_uri(uri)
      scheme, _, path, _ = split_file_uri(uri)

      unless scheme == 'file-digest'
        raise URI::InvalidURIError, "expected file-digest scheme: #{uri}"
      end

      path
    end

    # Internal: Build file-digest dependency URI.
    #
    # Examples
    #
    #   build("/tmp/js/application.js")
    #   # => "file-digest:/tmp/js/application.js"
    #
    # path - String file path
    #
    # Returns String URI.
    def build_file_digest_uri(path)
      join_file_uri("file-digest", nil, path, nil)
    end

    # Internal: Build processor dependency URI.
    #
    #
    # type - String or Symbol processor type (preprocessor, postprocessor, ...)
    # processor - Processor callable object
    # params - Hash of associated metadata
    #
    # Returns String URI.
    def build_processor_uri(type, processor = nil, params = {})
      if processor
        if processor.respond_to?(:name)
          params[:name] = processor.name.to_s
        elsif processor && processor.class.respond_to?(:name)
          params[:class_name] = processor.class.name.to_s
        end
      end

      query = encode_uri_query_params(params)
      uri = "processor:#{type}"
      uri << "?#{query}" if query
      uri
    end

    # Internal: Serialize hash of params into query string.
    #
    # params - Hash of params to serialize
    #
    # Returns String query or nil if empty.
    def encode_uri_query_params(params)
      query = []

      params.each do |key, value|
        case value
        when Integer
          query << "#{key}=#{value}"
        when String
          query << "#{key}=#{URI::Generic::DEFAULT_PARSER.escape(value)}"
        when TrueClass
          query << "#{key}"
        when FalseClass, NilClass
        else
          raise TypeError, "unexpected type: #{value.class}"
        end
      end

      "#{query.join('&')}" if query.any?
    end
  end
end
