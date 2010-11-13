require 'thread'
require 'time'

module Sprockets
  class Server
    attr_accessor :environment, :lock, :assets

    def initialize(environment = Environment.new)
      self.environment = environment
      self.lock        = Mutex.new
      self.assets      = {}
    end

    def call(env)
      if forbidden_request?(env)
        return forbidden_response
      end

      asset = rebundle(env)

      if not_modified?(asset, env) || etag_match?(asset, env)
        not_modified_response(asset, env)
      elsif asset.empty?
        not_found_response
      else
        ok_response(asset, env)
      end
    end

    def lookup_md5(path)
      if asset = rebundle("PATH_INFO" => path)
        asset.md5
      end
    end

    protected
      def lookup_asset(env)
        self.assets[env["PATH_INFO"]]
      end

      def rebundle(env)
        if env["rack.multithread"]
          synchronized_rebundle(env)
        else
          rebundle!(env)
        end
      end

      def synchronized_rebundle(env)
        asset = lookup_asset(env)
        if asset_stale?(asset)
          lock.synchronize { rebundle!(env) }
        else
          asset
        end
      end

      def rebundle!(env)
        asset = lookup_asset(env)
        if asset_stale?(asset)
          path_info = env["PATH_INFO"]
          asset = environment[path_info]
          assets = self.assets.dup
          assets[path_info] = asset
          self.assets = assets
        end
        asset
      end

      def asset_stale?(asset)
        asset.nil? || asset.stale?
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
        env["HTTP_IF_NONE_MATCH"] == asset.etag
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

          headers["Cache-Control"]  = "public, must-revalidate"
          headers["Last-Modified"]  = asset.mtime.httpdate
          headers["ETag"]           = asset.etag

          if env["QUERY_STRING"] == asset.md5
            headers["Cache-Control"] << ", max-age=31557600"
          end
        end
      end
  end
end
