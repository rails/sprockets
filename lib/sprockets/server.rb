require 'time'

module Sprockets
  module Server
    def call(env)
      self.multithread = env["rack.multithread"]

      if forbidden_request?(env)
        return forbidden_response
      end

      asset = self[env['PATH_INFO']]

      if asset.nil?
        not_found_response
      elsif not_modified?(asset, env) || etag_match?(asset, env)
        not_modified_response(asset, env)
      else
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
        [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9", "X-Cascade" => "pass" }, [ "Not found" ] ]
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

          if Pathname.new(env["PATH_INFO"]).fingerprint
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
