require 'sprockets/errors'
require 'uri'

module Sprockets
  module AssetURI
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
    def self.parse(str)
      uri = URI(str)

      unless uri.scheme == 'file'
        raise URI::InvalidURIError, "expected file:// scheme: #{str}"
      end

      path = URI::Generic::DEFAULT_PARSER.unescape(uri.path)
      path.force_encoding(Encoding::UTF_8)

      params = uri.query.to_s.split('&').reduce({}) do |h, p|
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
    def self.build(path, params = {})
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

    # Internal: Merge new parameters into String URI.
    #
    # str        - String asset URI
    # new_params - Hash of symbolized parameters
    #
    # Returns String URI.
    def self.merge(str, new_params = {})
      path, params = parse(str)
      build(path, params.merge(new_params))
    end
  end
end
