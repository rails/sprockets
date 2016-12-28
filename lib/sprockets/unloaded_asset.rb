# frozen_string_literal: true
require 'sprockets/uri_utils'
require 'sprockets/uri_tar'

module Sprockets
  # Internal: Used to parse and store the URI to an unloaded asset
  # Generates keys used to store and retrieve items from cache
  class UnloadedAsset

    # Internal: Initialize object for generating cache keys
    #
    # uri - A String containing complete URI to a file including scheme
    #       and full path such as
    #       "file:///Path/app/assets/js/app.js?type=application/javascript"
    # env - The current "environment" that assets are being loaded into.
    #       We need it so we know where the +root+ (directory where Sprockets
    #       is being invoked). We also need it for the `file_digest` method,
    #       since, for some strange reason, memoization is provided by
    #       overriding methods such as `stat` in the `PathUtils` module.
    #
    # Returns UnloadedAsset.
    def initialize(uri, env)
      @uri               = uri.to_s
      @env               = env
      @compressed_path   = URITar.new(uri, env).compressed_path
      # lazy loaded
      @params            = nil
      @filename          = nil
      @load_path         = nil
      @logical_path      = nil
      @file_type         = nil
      @initial_logical_path = nil
    end
    attr_reader :compressed_path, :uri

    # Internal: Full file path without schema
    #
    # This returns a string containing the full path to the asset without the schema.
    # Information is loaded lazily since we want `UnloadedAsset.new(dep, self).relative_path`
    # to be fast. Calling this method the first time allocates an array and a hash.
    #
    # Example
    #
    # If the URI is `file:///Full/path/app/assets/javascripts/application.js"` then the
    # filename would be `"/Full/path/app/assets/javascripts/application.js"`
    #
    # Returns a String.
    def filename
      unless @filename
        load_file_params
      end
      @filename
    end

    # Internal: Hash of param values
    #
    # This information is generated and used internally by Sprockets.
    # Known keys include `:type` which stores the asset's mime-type, `:id` which is a fully resolved
    # digest for the asset (includes dependency digest as opposed to a digest of only file contents)
    # and `:pipeline`. Hash may be empty.
    #
    # Example
    #
    # If the URI is `file:///Full/path/app/assets/javascripts/application.js"type=application/javascript`
    # Then the params would be `{type: "application/javascript"}`
    #
    # Returns a Hash.
    def params
      unless @params
        load_file_params
      end
      @params
    end

    # Internal: Key of asset
    #
    # Used to retrieve an asset from the cache based on "compressed" path to asset.
    # A "compressed" path can either be relative to the root of the project or an
    # absolute path.
    #
    # Returns a String.
    def asset_key
      "asset-uri:#{compressed_path}"
    end

    # Public: Dependency History key
    #
    # Used to retrieve an array of "histories" each of which contains a set of stored dependencies
    # for a given asset path and filename digest.
    #
    # A dependency can refer to either an asset e.g. index.js
    # may rely on jquery.js (so jquery.js is a dependency), or other factors that may affect
    # compilation, such as the VERSION of Sprockets (i.e. the environment) and what "processors"
    # are used.
    #
    # For example a history array with one Set of dependencies may look like:
    #
    # [["environment-version", "environment-paths", "processors:type=text/css&file_type=text/css",
    #   "file-digest:///Full/path/app/assets/stylesheets/application.css",
    #   "processors:type=text/css&file_type=text/css&pipeline=self",
    #   "file-digest:///Full/path/app/assets/stylesheets"]]
    #
    # This method of asset lookup is used to ensure that none of the dependencies have been modified
    # since last lookup. If one of them has, the key will be different and a new entry must be stored.
    #
    # URI dependencies are later converted to "compressed" paths
    #
    # Returns a String.
    def dependency_history_key
      "asset-uri-cache-dependencies:#{compressed_path}:#{ @env.file_digest(filename) }"
    end

    # Internal: Digest key
    #
    # Used to retrieve a string containing the "compressed" path to an asset based on
    # a digest. The digest is generated from dependencies stored via information stored in
    # the `dependency_history_key` after each of the "dependencies" is "resolved".
    # For example "environment-version" may be resolved to "environment-1.0-3.2.0"
    # for version "3.2.0" of Sprockets
    #
    # Returns a String.
    def digest_key(digest)
      "asset-uri-digest:#{compressed_path}:#{digest}"
    end

    # Internal: File digest key
    #
    # The digest for a given file won't change if the path and the stat time hasn't changed
    # We can save time by not re-computing this information and storing it in the cache
    #
    # Returns a String.
    def file_digest_key(stat)
      "file_digest:#{compressed_path}:#{stat}"
    end

    def source_path
      @source_path ||= begin
        digest      = @env.file_digest(self.filename)
        hex         = DigestUtils.pack_hexdigest(digest)
        source_path = self.logical_path.sub(/\.(\w+)$/) { |ext| "-#{hex}#{ext}" }
        source_path
      end
    end

    def load_path
      split_logical_and_load_path
      @load_path
    end

    def type
      params[:type]
    end

    def file_type
      unless @file_type
        name
      end
      @file_type
    end

    def name
      @name ||= begin
        split_logical_and_load_path
        extname, @file_type = @env.match_path_extname(@initial_logical_path, @env.mime_exts)
        name = @initial_logical_path.chomp(extname)
        name
      end
    end

    def logical_path
      @logical_path ||= begin
        logical_path = self.name.dup

        if pipeline = self.params[:pipeline]
          logical_path << ".#{pipeline}"
        end

        if type = self.params[:type]
          logical_path << @env.config[:mime_types][type][:extensions].first
        end
        logical_path
      end
    end

    def initial_logical_path
      unless @initial_logical_path
        split_logical_and_load_path
      end
      @initial_logical_path
    end

    private
      # Internal: Parses uri into filename and params hash
      #
      # Returns Array with filename and params hash
      def load_file_params
        @filename, @params = URIUtils.parse_asset_uri(uri)
      end

      def split_logical_and_load_path
        return if @load_path

        path_to_split =
          if index_alias = self.params[:index_alias]
            @env.expand_from_root index_alias
          else
            self.filename
          end

        @load_path, @initial_logical_path = @env.paths_split(@env.config[:paths], path_to_split)

        if @load_path.nil?
          target = path_to_split
          target += " (index alias of #{self.filename})" if self.params[:index_alias]
          raise FileOutsidePaths, "#{target} is no longer under a load path: #{@env.paths.join(', ')}"
        end
      end
  end
end
