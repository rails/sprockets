require 'set'
require 'sprockets/http_utils'
require 'sprockets/path_dependency_utils'
require 'sprockets/uri_utils'

module Sprockets
  module Resolve
    include HTTPUtils, PathDependencyUtils, URIUtils

    # Public: Find Asset URI for given a logical path by searching the
    # environment's load paths.
    #
    #     resolve("application.js")
    #     # => "file:///path/to/app/javascripts/application.js?type=application/javascript"
    #
    # An accept content type can be given if the logical path doesn't have a
    # format extension.
    #
    #     resolve("application", accept: "application/javascript")
    #     # => "file:///path/to/app/javascripts/application.coffee?type=application/javascript"
    #
    # The String Asset URI is returned or nil if no results are found.
    def resolve(path, load_paths: config[:paths], accept: nil, pipeline: nil, base_path: nil)
      paths = load_paths

      if valid_asset_uri?(path)
        uri, deps = resolve_asset_uri(path)
      elsif absolute_path?(path)
        filename, type, deps = resolve_absolute_path(paths, path, accept)
      elsif relative_path?(path)
        filename, type, path_pipeline, deps, index_alias = resolve_relative_path(paths, path, base_path, accept)
      else
        filename, type, path_pipeline, deps, index_alias = resolve_logical_path(paths, path, accept)
      end

      if filename
        uri = build_asset_uri(filename, type: type, pipeline: pipeline || path_pipeline, index_alias: index_alias)
      end

      return uri, deps
    end

    # Public: Same as resolve() but raises a FileNotFound exception instead of
    # nil if no assets are found.
    def resolve!(path, **kargs)
      uri, deps = resolve(path, **kargs)

      unless uri
        message = "couldn't find file '#{path}'"

        if relative_path?(path) && kargs[:base_path]
          load_path, _ = paths_split(config[:paths], kargs[:base_path])
          message << " under '#{load_path}'"
        end

        message << " with type '#{kargs[:accept]}'" if kargs[:accept]

        raise FileNotFound, message
      end

      return uri, deps
    end

    protected
      def resolve_asset_uri(uri)
        filename, _ = parse_asset_uri(uri)
        return uri, Set.new([build_file_digest_uri(filename)])
      end

      def resolve_absolute_path(paths, filename, accept)
        deps = Set.new
        filename = File.expand_path(filename)

        # Ensure path is under load paths
        return nil, nil, deps unless paths_split(paths, filename)

        _, mime_type = match_path_extname(filename, config[:mime_exts])
        type = resolve_transform_type(mime_type, accept)
        return nil, nil, deps if accept && !type

        return nil, nil, deps unless file?(filename)

        deps << build_file_digest_uri(filename)
        return filename, type, deps
      end

      def resolve_relative_path(paths, path, dirname, accept)
        filename = File.expand_path(path, dirname)
        load_path, _ = paths_split(paths, dirname)
        if load_path && logical_path = split_subpath(load_path, filename)
          resolve_logical_path([load_path], logical_path, accept)
        else
          return nil, nil, nil, Set.new
        end
      end

      def resolve_logical_path(paths, logical_path, accept)
        extname, mime_type = match_path_extname(logical_path, config[:mime_exts])
        logical_name = logical_path.chomp(extname)

        extname, pipeline = match_path_extname(logical_name, config[:pipeline_exts])
        logical_name = logical_name.chomp(extname)

        parsed_accept = parse_accept_options(mime_type, accept)
        transformed_accepts = expand_transform_accepts(parsed_accept)

        filename, mime_type, deps, index_alias = resolve_under_paths(paths, logical_name, transformed_accepts)

        if filename
          deps << build_file_digest_uri(filename)
          type = resolve_transform_type(mime_type, parsed_accept)
          return filename, type, pipeline, deps, index_alias
        else
          return nil, nil, nil, deps
        end
      end

      def resolve_under_paths(paths, logical_name, accepts)
        deps = Set.new
        return nil, nil, deps if accepts.empty?

        mime_exts = config[:mime_exts]
        paths.each do |load_path|
          # TODO: Allow new path resolves to be registered
          fns = [
            method(:resolve_main_under_path),
            method(:resolve_alts_under_path),
            method(:resolve_index_under_path)
          ]

          candidates = []
          fns.each do |fn|
            result = fn.call(load_path, logical_name, mime_exts)
            candidates.concat(result[0])
            deps.merge(result[1])
          end

          candidate = find_best_q_match(accepts, candidates) do |c, matcher|
            match_mime_type?(c[:type] || "application/octet-stream", matcher)
          end
          return candidate[:filename], candidate[:type], deps, candidate[:index_alias] if candidate
        end

        return nil, nil, deps
      end

      def resolve_main_under_path(load_path, logical_name, mime_exts)
        dirname    = File.dirname(File.join(load_path, logical_name))
        candidates = find_matching_path_for_extensions(dirname, File.basename(logical_name), mime_exts)
        return candidates.map { |c|
          { filename: c[0], type: c[1] }
        }, [build_file_digest_uri(dirname)]
      end

      def resolve_alts_under_path(load_path, logical_name, mime_exts)
        filenames, deps = self.resolve_alternates(load_path, logical_name)
        return filenames.map { |fn|
          _, mime_type = match_path_extname(fn, mime_exts)
          { filename: fn, type: mime_type }
        }, deps
      end

      def resolve_index_under_path(load_path, logical_name, mime_exts)
        dirname = File.join(load_path, logical_name)
        deps = [build_file_digest_uri(dirname)]
        candidates = []
        if directory?(dirname)
          candidates = find_matching_path_for_extensions(dirname, "index", mime_exts)
        end
        return candidates.map { |c|
          { filename: c[0], type: c[1], index_alias: c[0].gsub(/\/index(\.\w{2,4})$/, '\1') }
        }, deps
      end

      def parse_accept_options(mime_type, types)
        accepts = []
        accepts += parse_q_values(types) if types

        if mime_type
          if accepts.empty? || accepts.any? { |accept, _| match_mime_type?(mime_type, accept) }
            accepts = [[mime_type, 1.0]]
          else
            return []
          end
        end

        if accepts.empty?
          accepts << ['*/*', 1.0]
        end

        accepts
      end

      def resolve_alternates(load_path, logical_name)
        return [], Set.new
      end
  end
end
