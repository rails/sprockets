require 'set'
require 'sprockets/path_dependency_utils'
require 'sprockets/uri_utils'

module Sprockets
  module Resolve
    include PathDependencyUtils, URIUtils

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
    def resolve(path, options = {})
      path = path.to_s
      accept = options[:accept]
      skip_bundle = options.key?(:bundle) ? !options[:bundle] : false

      paths = options[:load_paths] || self.paths

      if valid_asset_uri?(path)
        uri = path
        filename, _ = parse_asset_uri(uri)
        return uri, Set.new([build_file_digest_uri(filename)])
      elsif absolute_path?(path)
        path = File.expand_path(path)
        if paths_split(paths, path) && file?(path)
          mime_type = parse_path_extnames(path)[1]
          _type = resolve_transform_type(mime_type, accept)
          if !accept || _type
            filename = path
            type = _type
            deps = Set.new
          end
        end
      else
        logical_name, mime_type, _ = parse_path_extnames(path)
        parsed_accept = parse_accept_options(mime_type, accept)
        transformed_accepts = expand_transform_accepts(parsed_accept)
        filename, mime_type, deps = resolve_under_paths(paths, logical_name, transformed_accepts)
        type = resolve_transform_type(mime_type, parsed_accept) if filename
      end

      if filename && deps
        uri = build_asset_uri(filename, type: type, skip_bundle: skip_bundle)
        deps << build_file_digest_uri(filename)
      end

      return uri, (deps || Set.new)
    end

    # TODO: Merge into resolve
    def resolve_relative(path, options = {})
      options = options.dup

      unless load_path = options.delete(:load_path)
        raise ArgumentError, "missing keyword: load_path"
      end

      unless dirname = options.delete(:dirname)
        raise ArgumentError, "missing keyword: dirname"
      end

      if path = split_relative_subpath(load_path, path, dirname)
        uri, deps = resolve(path, options.merge(load_paths: [load_path], compat: false))
      end

      return uri, (deps || Set.new)
    end

    def resolve!(path, options = {})
      if absolute_path?(path)
        # TODO: Delegate to env.resolve
        uri, deps = [build_asset_uri(path), [build_file_digest_uri(path)]]
      elsif relative_path?(path)
        # TODO: Route relative through resolve
        uri, deps = resolve_relative(path, options.merge(compat: false))
      else
        uri, deps = resolve(path, options.merge(compat: false))
      end

      unless uri
        accept = options[:accept]
        if relative_path?(path)
          dirname, load_path = options[:dirname], options[:load_path]
          if path = split_relative_subpath(load_path, path, dirname)
            message = "couldn't find file '#{path}' under '#{load_path}'"
            message << " with type '#{accept}'" if accept
            raise FileNotFound, message
          else
            raise FileOutsidePaths, "#{path} isn't under path: #{load_path}"
          end
        else
          message = "couldn't find file '#{path}'"
          message << " with type '#{accept}'" if accept
          raise FileNotFound, message
        end
      end

      return uri, deps
    end

    protected
      def resolve_under_paths(paths, logical_name, accepts)
        all_deps = Set.new
        return nil, nil, all_deps if accepts.empty?

        logical_basename = File.basename(logical_name)
        paths.each do |load_path|
          candidates, deps = path_matches(load_path, logical_name, logical_basename)
          all_deps.merge(deps)
          candidate = find_best_q_match(accepts, candidates) do |c, matcher|
            match_mime_type?(c[1] || "application/octet-stream", matcher)
          end
          return candidate + [all_deps] if candidate
        end

        return nil, nil, all_deps
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

      def normalize_logical_path(path)
        dirname, basename = File.split(path)
        path = dirname if basename == 'index'
        path
      end

      def path_matches(load_path, logical_name, logical_basename)
        candidates, deps = [], Set.new
        dirname = File.dirname(File.join(load_path, logical_name))

        result = dirname_matches(dirname, logical_basename)
        candidates.concat(result[0])
        deps.merge(result[1])

        result = resolve_alternates(load_path, logical_name)
        result[0].each do |fn|
          candidates << [fn, parse_path_extnames(fn)[1]]
        end
        deps.merge(result[1])

        result = dirname_matches(File.join(load_path, logical_name), "index")
        candidates.concat(result[0])
        deps.merge(result[1])

        return candidates.select { |fn, _| file?(fn) }, deps
      end

      def dirname_matches(dirname, basename)
        candidates = []
        entries, deps = self.entries_with_dependencies(dirname)
        entries.each do |entry|
          name, type, _ = parse_path_extnames(entry)
          if basename == name
            candidates << [File.join(dirname, entry), type]
          end
        end
        return candidates, deps
      end

      def resolve_alternates(load_path, logical_name)
        return [], Set.new
      end

      # Internal: Returns the name, mime type and `Array` of engine extensions.
      #
      #     "foo.js.coffee.erb"
      #     # => ["foo", "application/javascript", [".coffee", ".erb"]]
      #
      def parse_path_extnames(path)
        mime_type       = nil
        engine_extnames = []
        len = path.length

        path_extnames(path).reverse_each do |extname|
          if engines.key?(extname)
            mime_type = engine_mime_types[extname]
            engine_extnames.unshift(extname)
            len -= extname.length
          elsif mime_exts.key?(extname)
            mime_type = mime_exts[extname]
            len -= extname.length
            break
          else
            break
          end
        end

        name = path[0, len]
        return [name, mime_type, engine_extnames]
      end
  end
end
