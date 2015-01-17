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
    # str - String asset URI
    #
    # Returns String path and Hash of symbolized parameters.
    def parse_asset_uri(str)
      scheme, _, host, port, _, path, _, query, _ = URI.split(str)

      unless scheme == 'file'
        raise URI::InvalidURIError, "expected file:// scheme: #{str}"
      end

      path = URI::Generic::DEFAULT_PARSER.unescape(path)
      path.force_encoding(Encoding::UTF_8)

      # Hack for parsing Windows "file://C:/Users/IEUser" paths
      if host && port == ""
        path = "#{host}:#{path}"
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
      query = []
      params.each do |key, value|
        case value
        when String
          query << "#{key}=#{value}"
        when TrueClass
          query << "#{key}"
        when FalseClass, NilClass
        else
          raise TypeError, "unexpected type: #{value.class}"
        end
      end

      uri = "file://#{URI::Generic::DEFAULT_PARSER.escape(path)}"
      uri << "?#{query.join('&')}" if query.any?
      uri
    end
  end
end
