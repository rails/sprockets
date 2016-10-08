# frozen_string_literal: true
require 'set'
require 'time'
require 'rack/utils'

module Sprockets
  # `Server` is a concern mixed into `Environment` and
  # `CachedEnvironment` that provides a Rack compatible `call`
  # interface and url generation helpers.
  module Server
    # Supported HTTP request methods.
    ALLOWED_REQUEST_METHODS = ['GET', 'HEAD'].to_set.freeze

    # `call` implements the Rack 1.x specification which accepts an
    # `env` Hash and returns a three item tuple with the status code,
    # headers, and body.
    #
    # Mapping your environment at a url prefix will serve all assets
    # in the path.
    #
    #     map "/assets" do
    #       run Sprockets::Environment.new
    #     end
    #
    # A request for `"/assets/foo/bar.js"` will search your
    # environment for `"foo/bar.js"`.
    def call(env)
      start_time = Time.now.to_f
      time_elapsed = lambda { ((Time.now.to_f - start_time) * 1000).to_i }

      unless ALLOWED_REQUEST_METHODS.include? env['REQUEST_METHOD']
        return method_not_allowed_response
      end

      msg = "Served asset #{env['PATH_INFO']} -"

      # Extract the path from everything after the leading slash
      path = Rack::Utils.unescape(env['PATH_INFO'].to_s.sub(/^\//, ''))

      # Strip fingerprint
      if fingerprint = path_fingerprint(path)
        path = path.sub("-#{fingerprint}", '')
      end

      # URLs containing a `".."` are rejected for security reasons.
      if forbidden_request?(path)
        return forbidden_response(env)
      end

      if fingerprint
        if_match = fingerprint
      elsif env['HTTP_IF_MATCH']
        if_match = env['HTTP_IF_MATCH'][/^"(\w+)"$/, 1]
      end

      if env['HTTP_IF_NONE_MATCH']
        if_none_match = env['HTTP_IF_NONE_MATCH'][/^"(\w+)"$/, 1]
      end

      # Look up the asset.
      asset = find_asset(path)

      if asset.nil?
        status = :not_found
      elsif fingerprint && asset.etag != fingerprint
        status = :not_found
      elsif if_match && asset.etag != if_match
        status = :precondition_failed
      elsif if_none_match && asset.etag == if_none_match
        status = :not_modified
      else
        status = :ok
      end

      case status
      when :ok
        logger.info "#{msg} 200 OK (#{time_elapsed.call}ms)"
        ok_response(asset, env)
      when :not_modified
        logger.info "#{msg} 304 Not Modified (#{time_elapsed.call}ms)"
        not_modified_response(env, if_none_match)
      when :not_found
        logger.info "#{msg} 404 Not Found (#{time_elapsed.call}ms)"
        not_found_response(env)
      when :precondition_failed
        logger.info "#{msg} 412 Precondition Failed (#{time_elapsed.call}ms)"
        precondition_failed_response(env)
      end
    rescue Exception => e
      logger.error "Error compiling asset #{path}:"
      logger.error "#{e.class.name}: #{e.message}"

      case File.extname(path)
      when ".js"
        # Re-throw JavaScript asset exceptions to the browser
        logger.info "#{msg} 500 Internal Server Error\n\n"
        return javascript_exception_response
      when ".css"
        # Display CSS asset exceptions in the browser
        logger.info "#{msg} 500 Internal Server Error\n\n"
        return css_exception_response
      else
        raise
      end
    end

    private
      def forbidden_request?(path)
        # Prevent access to files elsewhere on the file system
        #
        #     http://example.org/assets/../../../etc/passwd
        #
        path.include?("..") || absolute_path?(path)
      end

      def head_request?(env)
        env['REQUEST_METHOD'] == 'HEAD'
      end

      # Returns a 200 OK response tuple
      def ok_response(asset, env)
        if head_request?(env)
          [ 200, headers(env, asset, 0), [] ]
        else
          [ 200, headers(env, asset, asset.length), asset ]
        end
      end

      # Returns a 304 Not Modified response tuple
      def not_modified_response(env, etag)
        [ 304, cache_headers(env, etag), [] ]
      end

      # Returns a 403 Forbidden response tuple
      def forbidden_response(env)
        if head_request?(env)
          [ 403, { "Content-Type" => "text/plain", "Content-Length" => "0" }, [] ]
        else
          [ 403, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Forbidden" ] ]
        end
      end

      # Returns a 404 Not Found response tuple
      def not_found_response(env)
        if head_request?(env)
          [ 404, { "Content-Type" => "text/plain", "Content-Length" => "0", "X-Cascade" => "pass" }, [] ]
        else
          [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9", "X-Cascade" => "pass" }, [ "Not found" ] ]
        end
      end

      def method_not_allowed_response
        [ 405, { "Content-Type" => "text/plain", "Content-Length" => "18" }, [ "Method Not Allowed" ] ]
      end

      def precondition_failed_response(env)
        if head_request?(env)
          [ 412, { "Content-Type" => "text/plain", "Content-Length" => "0", "X-Cascade" => "pass" }, [] ]
        else
          [ 412, { "Content-Type" => "text/plain", "Content-Length" => "19", "X-Cascade" => "pass" }, [ "Precondition Failed" ] ]
        end
      end

      def javascript_exception_response
        [ 500, { "Content-Type" => "application/javascript", "Content-Length" => "21" }, [ "Internal Server Error" ] ]
      end

      def css_exception_response
        [ 500, { "Content-Type" => "text/css;charset=utf-8", "Content-Length" => "21" }, [ "Internal Server Error" ] ]
      end

      # Escape special characters for use inside a CSS content("...") string
      def escape_css_content(content)
        content.
          gsub('\\', '\\\\005c ').
          gsub("\n", '\\\\000a ').
          gsub('"',  '\\\\0022 ').
          gsub('/',  '\\\\002f ')
      end

      def cache_headers(env, etag)
        headers = {}

        # Set caching headers
        headers["Cache-Control"] = String.new("public")
        headers["ETag"]          = %("#{etag}")

        # If the request url contains a fingerprint, set a long
        # expires on the response
        if path_fingerprint(env["PATH_INFO"])
          headers["Cache-Control"] << ", max-age=31536000"

        # Otherwise set `must-revalidate` since the asset could be modified.
        else
          headers["Cache-Control"] << ", must-revalidate"
          headers["Vary"] = "Accept-Encoding"
        end

        headers
      end

      def headers(env, asset, length)
        headers = {}

        # Set content length header
        headers["Content-Length"] = length.to_s

        # Set content type header
        if type = asset.content_type
          # Set charset param for text/* mime types
          if type.start_with?("text/") && asset.charset
            type += "; charset=#{asset.charset}"
          end
          headers["Content-Type"] = type
        end

        headers.merge(cache_headers(env, asset.etag))
      end

      # Gets ETag fingerprint.
      #
      #     "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
      #     # => "0aa2105d29558f3eb790d411d7d8fb66"
      #
      def path_fingerprint(path)
        path[/-([0-9a-f]{7,128})\.[^.]+\z/, 1]
      end
  end
end
