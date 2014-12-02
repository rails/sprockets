require 'sprockets/asset_uri'

module Sprockets
  module Resolve
    # Public: Finds the absolute path for a given logical path by searching the
    # environment's load paths.
    #
    #     resolve("application.js")
    #     # => "/path/to/app/javascripts/application.js"
    #
    # An accept content type can be given if the logical path doesn't have a
    # format extension.
    #
    #     resolve("application", accept: "application/javascript")
    #     # => "/path/to/app/javascripts/application.js"
    #
    # The String path is returned or nil if no results are found.
    def resolve(path, options = {})
      logical_name, mime_type, _ = parse_path_extnames(path)

      paths = options[:load_paths] || self.paths

      if absolute_path?(path)
        path = File.expand_path(path)
        if paths_split(paths, path) && file?(path)
          if accept = options[:accept]
            find_best_q_match(accept, [path]) do |candidate, matcher|
              match_mime_type?(mime_type || "application/octet-stream", matcher)
            end
          else
            path
          end
        end
      else
        accepts = parse_accept_options(mime_type, options[:accept])
        filename, _ = resolve_under_paths(paths, logical_name, mime_type, accepts)
        filename
      end
    end

    # Public: Find Asset URI for given a logical path by searching the
    # environment's load paths.
    #
    #     locate("application.js")
    #     # => "file:///path/to/app/javascripts/application.js?content_type=application/javascript"
    #
    # An accept content type can be given if the logical path doesn't have a
    # format extension.
    #
    #     locate("application", accept: "application/javascript")
    #     # => "file:///path/to/app/javascripts/application.coffee?content_type=application/javascript"
    #
    # The String Asset URI is returned or nil if no results are found.
    def locate(path, options = {})
      path = path.to_s
      accept = options[:accept]
      skip_bundle = options.key?(:bundle) ? !options[:bundle] : false

      available_encodings = self.encodings.keys + ['identity']
      encoding = find_best_q_match(options[:accept_encoding], available_encodings)

      paths = options[:load_paths] || self.paths

      if AssetURI.valid?(path)
        return path
      elsif absolute_path?(path)
        path = File.expand_path(path)
        if paths_split(paths, path) && file?(path)
          mime_type = parse_path_extnames(path)[1]
          _type = resolve_transform_type(mime_type, accept)
          if !accept || _type
            filename = path
            type = _type
          end
        end
      else
        logical_name, mime_type, _ = parse_path_extnames(path)
        parsed_accept = parse_accept_options(mime_type, accept)

        if parsed_accept.empty?
          return
        end

        transformed_accepts = expand_transform_accepts(parsed_accept)
        filename, mime_type = resolve_under_paths(paths, logical_name, mime_type, transformed_accepts)
        type = resolve_transform_type(mime_type, parsed_accept) if filename
      end

      if filename
        encoding = nil if encoding == 'identity'
        AssetURI.build(filename, type: type, skip_bundle: skip_bundle, encoding: encoding)
      end
    end

    protected
      def resolve_under_paths(paths, logical_name, mime_type, accepts)
        logical_basename = File.basename(logical_name)

        paths.each do |load_path|
          candidates = path_matches(load_path, logical_name, logical_basename)
          candidate = find_best_q_match(accepts, candidates) do |c, matcher|
            match_mime_type?(c[1] || "application/octet-stream", matcher)
          end
          return candidate if candidate
        end

        nil
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
        candidates = []
        dirname = File.dirname(File.join(load_path, logical_name))
        dirname_matches(dirname, logical_basename) { |candidate| candidates << candidate }
        resolve_alternates(load_path, logical_name) { |fn| candidates << [fn, parse_path_extnames(fn)[1]] }
        dirname_matches(File.join(load_path, logical_name), "index") { |candidate| candidates << candidate }
        candidates.select { |fn, _| file?(fn) }
      end

      def dirname_matches(dirname, basename)
        self.entries(dirname).each do |entry|
          name, type, _ = parse_path_extnames(entry)
          if basename == name
            yield [File.join(dirname, entry), type]
          end
        end
      end

      def resolve_alternates(load_path, logical_name)
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
