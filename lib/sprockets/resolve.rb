require 'sprockets/asset_uri'

module Sprockets
  module Resolve
    # Finds the expanded real path for a given logical path by
    # searching the environment's paths.
    #
    #     resolve("application.js")
    #     # => "/path/to/app/javascripts/application.js.coffee"
    #
    # A `FileNotFound` exception is raised if the file does not exist.
    def resolve(path, options = {})
      logical_name, mime_type, _ = parse_path_extnames(path)
      logical_basename = File.basename(logical_name)

      accepts = parse_accept_options(mime_type, options[:accept])

      paths = options[:load_paths] || self.paths

      _resolve(logical_name, mime_type, logical_basename, accepts, paths)
    end

    # Experimental
    def locate(path, options = {})
      path = path.to_s
      accept = options[:accept]
      skip_bundle = options.key?(:bundle) ? !options[:bundle] : false

      available_encodings = self.encodings.keys + ['identity']
      encoding = find_best_q_match(options[:accept_encoding], available_encodings)

      paths = options[:load_paths] || self.paths

      if absolute_path?(path)
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
        logical_basename = File.basename(logical_name)
        parsed_accept = parse_accept_options(mime_type, accept)

        if parsed_accept.empty?
          return
        end

        tranformed_accepts = parsed_accept.reduce([]) do |ary, (t, q)|
          ary += [[t, q]] + self.inverted_transformers[t].keys.map { |t2| [t2, q * 0.5] }
        end

        if filename = _resolve(logical_name, mime_type, logical_basename, tranformed_accepts, paths)
          mime_type2 = parse_path_extnames(filename)[1]
          type = resolve_transform_type(mime_type2, parsed_accept)
        end
      end

      if filename
        encoding = nil if encoding == 'identity'
        AssetURI.build(filename, type: type, skip_bundle: skip_bundle, encoding: encoding)
      end
    end

    protected
      def _resolve(logical_name, mime_type, logical_basename, accepts, paths)
        paths.each do |load_path|
          filenames = path_matches(load_path, logical_name, logical_basename)

          matches = []

          # TODO: Cleanup double iteration of accept and filenames

          # Exact mime type match first
          matches += find_q_matches(accepts, filenames) do |filename, accepted|
            if !file?(filename)
              nil
            elsif accepted == '*/*'
              filename
            elsif parse_path_extnames(filename)[1] == accepted
              filename
            end
          end

          matches.uniq.each do |filename|
            return filename
          end
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
        filenames = []
        dirname = File.dirname(File.join(load_path, logical_name))
        dirname_matches(dirname, logical_basename) { |fn| filenames << fn }
        resolve_alternates(load_path, logical_name) { |fn| filenames << fn }
        dirname_matches(File.join(load_path, logical_name), "index") { |fn| filenames << fn }
        filenames
      end

      def dirname_matches(dirname, basename)
        self.entries(dirname).each do |entry|
          name = parse_path_extnames(entry)[0]
          if basename == name
            yield File.join(dirname, entry)
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
