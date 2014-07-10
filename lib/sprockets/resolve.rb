module Sprockets
  module Resolve
    # Public: Iterate over every file under all load paths.
    #
    # Returns Enumerator if no block is given.
    def each_file
      return to_enum(__method__) unless block_given?

      paths.each do |root|
        stat_tree(root).each do |filename, stat|
          if stat.file?
            yield filename
          end
        end
      end

      nil
    end

    # Finds the expanded real path for a given logical path by
    # searching the environment's paths.
    #
    #     resolve("application.js")
    #     # => "/path/to/app/javascripts/application.js.coffee"
    #
    # A `FileNotFound` exception is raised if the file does not exist.
    def resolve(path, options = {})
      resolve_all(path, options) do |filename|
        return filename
      end

      accept = options[:accept]
      message = "couldn't find file '#{path}'"
      message << " with type '#{accept}'" if accept
      raise FileNotFound, message
    end

    def resolve_in_load_path(load_path, logical_path, options = {})
      if !self.paths.include?(load_path.to_s)
        raise FileOutsidePaths, "#{load_path} isn't in paths: #{self.paths.join(', ')}"
      end

      resolve_all_under_load_path(load_path, logical_path, options) do |filename|
        return filename
      end

      accept = options[:accept]
      message = "couldn't find file '#{logical_path}' under '#{load_path}'"
      message << " with type '#{accept}'" if accept
      raise FileNotFound, message
    end

    def resolve_all_under_load_path(load_path, logical_path, options = {}, &block)
      return to_enum(__method__, load_path, logical_path, options) unless block_given?

      # TODO: Review performance
      logical_name, extname, _ = parse_path_extnames(logical_path)
      logical_basename = File.basename(logical_name)

      accepts = parse_accept_options(extname, options[:accept])

      accepts.each do |accept|
        path_matches(load_path, logical_name, logical_basename, extname) do |filename|
          if has_asset?(filename, accept: accept)
            yield filename
          end
        end
      end

      nil
    end

    # Public: Finds the expanded real path for a given logical path by searching
    # the environment's paths. Includes all matching paths including fallbacks
    # and shadowed matches.
    #
    #     resolve_all("application.js").first
    #     # => "/path/to/app/javascripts/application.js.coffee"
    #
    # `resolve_all` returns an `Enumerator`. This allows you to filter your
    # matches by any condition.
    #
    #     resolve_all("application").find do |path|
    #       mime_type_for(path) == "text/css"
    #     end
    #
    def resolve_all(path, options = {}, &block)
      return to_enum(__method__, path, options) unless block_given?
      path = path.to_s

      # TODO: Review performance
      logical_name, extname, _ = parse_path_extnames(path)
      logical_basename = File.basename(logical_name)

      accepts = parse_accept_options(extname, options[:accept])

      self.paths.each do |load_path|
        accepts.each do |accept|
          path_matches(load_path, logical_name, logical_basename, extname) do |filename|
            if has_asset?(filename, accept: accept)
              yield filename
            end
          end
        end
      end

      nil
    end

    # Public: Enumerate over all logical paths in the environment.
    #
    # Returns an Enumerator of [logical_path, filename].
    def logical_paths
      return to_enum(__method__) unless block_given?

      seen = Set.new

      self.paths.each do |load_path|
        stat_tree(load_path).each do |filename, stat|
          next unless stat.file?

          path = split_subpath(load_path, filename)
          path, extname, _ = parse_path_extnames(path)
          path = normalize_logical_path(path, extname)

          if !seen.include?(path)
            yield path, filename
            seen << path
          end
        end
      end

      nil
    end
    alias_method :each_logical_path, :logical_paths

    protected
      def parse_accept_options(extname, types)
        accepts = []
        accepts += types.split(/\s*,\s*/) if types

        if extname && (type = mime_exts[extname])
          if accepts.empty? || accepts.any? { |accept| match_mime_type?(type, accept) }
            accepts.unshift(type)
          else
            return []
          end
        end

        if accepts.empty?
          accepts << '*/*'
        end

        accepts
      end

      # TODO: Should logical path normalization still be supported?
      def normalize_logical_path(path, extname)
        dirname, basename = File.split(path)
        path = dirname if basename == 'index'
        path += extname if extname
        path
      end

      def path_matches(load_path, logical_name, logical_basename, extname, &block)
        dirname = File.dirname(File.join(load_path, logical_name))
        dirname_matches(dirname, "#{logical_basename}#{extname}", &block) if extname
        dirname_matches(dirname, logical_basename, &block)
        resolve_alternates(load_path, logical_name, &block)
        dirname_matches(File.join(load_path, logical_name), "index", &block)
      end

      def dirname_matches(dirname, basename)
        self.entries(dirname).each do |entry|
          # TODO: Review performance
          name = parse_path_extnames(entry)[0]
          if basename == name
            yield File.join(dirname, entry)
          end
        end
      end

      def resolve_alternates(load_path, logical_name)
      end

      # Internal: Returns the format extension and `Array` of engine extensions.
      #
      #     "foo.js.coffee.erb"
      #     # => { format: ".js",
      #            engines: [".coffee", ".erb"] }
      #
      # TODO: Review API and performance
      def parse_path_extnames(path)
        format_extname  = nil
        engine_extnames = []
        len = path.length

        path_extnames(path).reverse_each do |extname|
          if engines.key?(extname)
            format_extname = engine_extensions[extname]
            engine_extnames.unshift(extname)
            len -= extname.length
          elsif mime_exts.key?(extname)
            format_extname = extname
            len -= extname.length
            break
          else
            break
          end
        end

        name = path[0, len]
        return [name, format_extname, engine_extnames]
      end
  end
end
