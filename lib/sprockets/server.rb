require 'time'

module Sprockets
  class Server
    attr_accessor :environment

    def initialize(environment = Environment.new)
      self.environment = environment
    end

    def logger
      environment.logger
    end

    def call(env)
      logger.info "[Sprockets] #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
      environment.multithread = env["rack.multithread"]

      if forbidden_request?(env)
        logger.info "[Sprockets] Forbidden"
        return forbidden_response
      end

      # foo-acbd18db4cc2f85cedef654fccc4a4d8.js
      if env['PATH_INFO'].split('/').last =~ /^[^.]+-([0-9a-f]{7,40})\./
        env['QUERY_STRING'] = $1
        env['PATH_INFO'] = env['PATH_INFO'].sub("-#{$1}", "")
      end

      asset = environment[env['PATH_INFO'], env["QUERY_STRING"]]

      if asset.nil?
        logger.info "[Sprockets] Not Found"
        not_found_response
      elsif not_modified?(asset, env) || etag_match?(asset, env)
        logger.info "[Sprockets] Not Modified"
        not_modified_response(asset, env)
      else
        logger.info "[Sprockets] OK"
        ok_response(asset, env)
      end
    end

    private
      def forbidden_request?(env)
        env["PATH_INFO"].include?("..")
      end

      def forbidden_response
        [ 403, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Forbidden" ] ]
      end

      def not_found_response
        [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Not found" ] ]
      end

      def not_modified?(asset, env)
        env["HTTP_IF_MODIFIED_SINCE"] == asset.mtime.httpdate
      end

      def etag_match?(asset, env)
        env["HTTP_IF_NONE_MATCH"] == etag(asset)
      end

      def not_modified_response(asset, env)
        [ 304, {}, [] ]
      end

      def ok_response(asset, env)
        [ 200, headers(asset, env), asset ]
      end

      def headers(asset, env)
        Hash.new.tap do |headers|
          headers["Content-Type"]   = asset.content_type
          headers["Content-Length"] = asset.length.to_s
          headers["Content-MD5"]    = asset.digest

          headers["Cache-Control"]  = "public"
          headers["Last-Modified"]  = asset.mtime.httpdate
          headers["ETag"]           = etag(asset)

          if env["QUERY_STRING"] == asset.digest
            headers["Cache-Control"] << ", max-age=31536000"
          else
            headers["Cache-Control"] << ", must-revalidate"
          end
        end
      end

      def etag(asset)
        %("#{asset.digest}")
      end
  end
end
