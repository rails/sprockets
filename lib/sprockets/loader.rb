require 'sprockets/asset'
require 'sprockets/digest_utils'
require 'sprockets/engines'
require 'sprockets/errors'
require 'sprockets/file_reader'
require 'sprockets/mime'
require 'sprockets/path_utils'
require 'sprockets/processing'
require 'sprockets/processor_utils'
require 'sprockets/resolve'
require 'sprockets/transformers'
require 'sprockets/uri_utils'

module Sprockets

  # Internal: Used to parse and store the URI to an unloaded asset
  # Generates keys used to store and retrieve items from cache
  class UnloadedAsset

    # Internal: Initialize object for generating cache keys
    #
    # uri - A String containing complete URI to a file including schema
    #       and full path such as
    #       "file:///Path/app/assets/js/app.js?type=application/javascript"
    # env - The current "environment" that assets are being loaded into.
    #       We need it so we know where the +root+ (directory where sprockets
    #       is being invoked). We also need for the `file_digest` method,
    #       since, for some strange reason, memoization is provided by
    #       overriding methods such as `stat` in the `PathUtils` module.
    #
    # Returns UnloadedAsset.
    def initialize(uri, env)
      @uri             = uri
      @env             = env
      @root            = env.root
      @relative_path   = get_relative_path_from_uri
      @params          = nil # lazy loaded
      @filename        = nil # lazy loaded
    end
    attr_reader :relative_path, :root, :uri


    # Internal: Full file path without schema
    #
    # This returns a string containing the full path to the asset without the schema.
    # Information is loaded lazilly since we want `UnloadedAsset.new(dep, self).relative_path`
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
    # This information is generated and used internally by sprockets.
    # Known keys include `:type` which store the asset's mime-type, `:id` which is a fully resolved
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
    # Used to retrieve an asset from the cache based on relative path to asset
    #
    # Returns a String.
    def asset_key
      "asset-uri:#{relative_path}"
    end

    # Public: Dependency History key
    #
    # Used to retrieve an array of "histories" each of which contain a set of stored dependencies
    # for a given asset path and filename digest.
    #
    # A dependency can refer to either an asset i.e. index.js
    # may rely on jquery.js (so jquery.js is a dependency), or other factors that may affect
    # compilation, such as the VERSION of sprockets (i.e. the environment) and what "processors"
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
    # URI depndencies are later converted to relative paths
    #
    # Returns a String.
    def dependency_history_key
      "asset-uri-cache-dependencies:#{relative_path}:#{ @env.file_digest(filename) }"
    end

    # Internal: Digest key
    #
    # Used to retrieve a string containing the relative path to an asset based on
    # a digest. The digest is generated from dependencies stored via information stored in
    # the `dependency_history_key` after each of the "dependencies" is "resolved" for example
    # "environment-version" may be resolved to "environment-1.0-3.2.0" for version "3.2.0" of sprockets
    #
    # Returns a String.
    def digest_key(digest)
      "asset-uri-digest:#{relative_path}:#{digest}"
    end

    # Internal: File digest key
    #
    # The digest for a given file won't change if the path and the stat time hasn't changed
    # We can save time by not re-computing this information and storing it in the cache
    #
    # Returns a String.
    def file_digest_key(stat)
      "file_digest:#{relative_path}:#{stat}"
    end

    private
      # Internal: Parses uri into filename and params hash
      #
      # Returns Array with filename and params hash
      def load_file_params
        @filename, @params = URIUtils.parse_asset_uri(uri)
      end

      # Internal: Converts uri to a relative path
      #
      # Returns a relative path if given URI is in the `@env.root` of where sprockets
      # is running. Otherwise it returns a string of the absolute path
      #
      # Returns a String.
      def get_relative_path_from_uri
        path = uri.sub(/\Afile:\/\//, "".freeze)
        if relative_path = PathUtils.split_subpath(root, path)
          relative_path
        else
          path
        end
      end
  end
  # The loader phase takes a asset URI location and returns a constructed Asset
  # object.
  module Loader
    include DigestUtils, PathUtils, ProcessorUtils, URIUtils
    include Engines, Mime, Processing, Resolve, Transformers


    # Public: Load Asset by Asset URI.
    #
    # uri - A String containing complete URI to a file including schema
    #       and full path such as:
    #       "file:///Path/app/assets/js/app.js?type=application/javascript"
    #
    #
    # Returns Asset.
    def load(uri)
      unloaded = UnloadedAsset.new(uri, self)
      if unloaded.params.key?(:id)
        unless asset = cache.get(unloaded.asset_key, true)
          id = unloaded.params.delete(:id)
          uri_without_id = build_asset_uri(unloaded.filename, unloaded.params)
          asset = load_from_unloaded(UnloadedAsset.new(uri_without_id, self))
          if asset[:id] != id
            @logger.warn "Sprockets load error: Tried to find #{uri}, but latest was id #{asset[:id]}"
          end
        end
      else
        asset = fetch_asset_from_dependency_cache(unloaded) do |paths|
          # When asset is previously generated, its "dependencies" are stored in the cache.
          # The presence of `paths` indicates dependencies were stored.
          # We can check to see if the dependencies have not changed by "resolving" them and
          # generating a digest key from the resolved entries. If this digest key has not
          # changed the asset will be pulled from cache.
          #
          # If this `paths` is present but the cache returns nothing then `fetch_asset_from_dependency_cache`
          # will confusingly be called again with `paths` set to nil where the asset will be
          # loaded from disk.
          if paths
            digest = DigestUtils.digest(resolve_dependencies(paths))
            if uri_from_cache = cache.get(unloaded.digest_key(digest), true)
              cache.get(UnloadedAsset.new(uri_from_cache, self).asset_key, true)
            end
          else
            load_from_unloaded(unloaded)
          end
        end
      end
      Asset.new(self, asset)
    end

    private

      # Internal: Loads an asset and saves it to cache
      #
      # unloaded - An UnloadedAsset
      #
      # This method is only called when the given unloaded asset could not be
      # successfully pulled from cache.
      def load_from_unloaded(unloaded)
        unless file?(unloaded.filename)
          raise FileNotFound, "could not find file: #{unloaded.filename}"
        end

        load_path, logical_path = paths_split(config[:paths], unloaded.filename)

        unless load_path
          raise FileOutsidePaths, "#{unloaded.filename} is no longer under a load path: #{self.paths.join(', ')}"
        end

        logical_path, file_type, engine_extnames, _ = parse_path_extnames(logical_path)
        name = logical_path

        if pipeline = unloaded.params[:pipeline]
          logical_path += ".#{pipeline}"
        end

        if type = unloaded.params[:type]
          logical_path += config[:mime_types][type][:extensions].first
        end

        if type != file_type && !config[:transformers][file_type][type]
          raise ConversionError, "could not convert #{file_type.inspect} to #{type.inspect}"
        end

        processors = processors_for(type, file_type, engine_extnames, pipeline)

        processors_dep_uri = build_processors_uri(type, file_type, engine_extnames, pipeline)
        dependencies = config[:dependencies] + [processors_dep_uri]

        # Read into memory and process if theres a processor pipeline
        if processors.any?
          result = call_processors(processors, {
            environment: self,
            cache: self.cache,
            uri: unloaded.uri,
            filename: unloaded.filename,
            load_path: load_path,
            name: name,
            content_type: type,
            metadata: { dependencies: dependencies }
          })
          validate_processor_result!(result)
          source = result.delete(:data)
          metadata = result.merge!(
            charset: source.encoding.name.downcase,
            digest: digest(source),
            length: source.bytesize
          )
        else
          dependencies << build_file_digest_uri(unloaded.filename)
          metadata = {
            digest: file_digest(unloaded.filename),
            length: self.stat(unloaded.filename).size,
            dependencies: dependencies
          }
        end

        asset = {
          uri: unloaded.uri,
          load_path: load_path,
          filename: unloaded.filename,
          name: name,
          logical_path: logical_path,
          content_type: type,
          source: source,
          metadata: metadata,
          dependencies_digest: DigestUtils.digest(resolve_dependencies(metadata[:dependencies]))
        }

        asset[:id]  = pack_hexdigest(digest(asset))
        asset[:uri] = build_asset_uri(unloaded.filename, unloaded.params.merge(id: asset[:id]))

        # Deprecated: Avoid tracking Asset mtime
        asset[:mtime] = metadata[:dependencies].map { |u|
          if u.start_with?("file-digest:")
            s = self.stat(parse_file_digest_uri(u))
            s ? s.mtime.to_i : nil
          else
            nil
          end
        }.compact.max
        asset[:mtime] ||= self.stat(unloaded.filename).mtime.to_i

        # Unloaded asset and stored_asset now have a different URI
        stored_asset = UnloadedAsset.new(asset[:uri], self)

        # Save the asset in the cache under the new URI
        cache.set(stored_asset.asset_key, asset, true)

        # Save the new relative path for the digest key of the unloaded asset
        cache.set(unloaded.digest_key(asset[:dependencies_digest]), stored_asset.relative_path, true) # wat

        asset
      end


      # Internal: Resolve set of dependency URIs.
      #
      # uris - An Array of "dependencies" for example:
      #        ["environment-version", "environment-paths", "processors:type=text/css&file_type=text/css",
      #           "file-digest:///Full/path/app/assets/stylesheets/application.css",
      #           "processors:type=text/css&file_type=text/css&pipeline=self",
      #           "file-digest:///Full/path/app/assets/stylesheets"]
      #
      # Returns back array of things that the given uri dpends on
      # For example the environment version, if you're using a different version of sprockets
      # then the dependencies should be different, this is used only for generating cache key
      # for example the "environment-version" may be resolved to "environment-1.0-3.2.0" for
      #  version "3.2.0" of sprockets.
      #
      # Any paths that are returned are converted to relative paths
      #
      # Returns array of resolved dependencies
      def resolve_dependencies(uris)
        uris.map do |uri|
          dependency = resolve_dependency(uri)
          case dependency
          when Array
            dependency.map do |dep|
              if dep && dep.is_a?(String)
                UnloadedAsset.new(dep, self).relative_path
              else
                dep
              end
            end
          else
            dependency
          end
        end
      end

      # Internal: Retrieves an asset based on its digest
      #
      # unloaded - An UnloadedAsset
      # limit    - A Fixnum which sets the maximum number of versions of "histories"
      #            stored in the cache
      #
      # This method attempts to retrieve the last `limit` number of histories of an asset
      # from the cache a "history" which is an array of unresolved "dependencies" that the asset needs
      # to compile. In this case A dependency can refer to either an asset i.e. index.js
      # may rely on jquery.js (so jquery.js is a depndency), or other factors that may affect
      # compilation, such as the VERSION of sprockets (i.e. the environment) and what "processors"
      # are used.
      #
      # For example a history array may look something like this
      #
      #   [["environment-version", "environment-paths", "processors:type=text/css&file_type=text/css",
      #     "file-digest:///Full/path/app/assets/stylesheets/application.css",
      #     "processors:type=text/css&file_type=text/css&pipeline=self",
      #     "file-digest:///Full/path/app/assets/stylesheets"]]
      #
      # Where the first entry is a Set of dependencies for last generated version of that asset.
      # Multiple versions are stored since sprockets keeps the last `limit` number of assets
      # generated present in the system.
      #
      # If a "history" of dependencies is present in the cache, each version of "history" will be
      # yielded to the passed block which is responsible for loading the asset. If found, the existing
      # history will be saved with the dependency that found a valid asset moved to the front.
      #
      # If no history is present, or if none of the histories could be resolved to a valid asset then,
      # the block is yielded to and expected to return a valid asset.
      # When this happens the dependencies for the returned asset are added to the "history", and older
      # entries are removed if the "history" is above `limit`.
      def fetch_asset_from_dependency_cache(unloaded, limit = 3)
        key = unloaded.dependency_history_key

        history = cache.get(key) || []
        history.each_with_index do |deps, index|
          if asset = yield(deps)
            cache.set(key, history.rotate!(index)) if index > 0
            return asset
          end
        end

        asset = yield
        deps = asset[:metadata][:dependencies]
        cache.set(key, history.unshift(deps).take(limit))
        asset
      end
  end
end
