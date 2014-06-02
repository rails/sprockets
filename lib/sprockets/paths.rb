module Sprockets
  module Paths
    # Returns `Environment` root.
    #
    # All relative paths are expanded with root as its base. To be
    # useful set this to your applications root directory. (`Rails.root`)
    attr_reader :root

    # Returns an `Array` of path `String`s.
    #
    # These paths will be used for asset logical path lookups.
    attr_reader :paths

    # Prepend a `path` to the `paths` list.
    #
    # Paths at the end of the `Array` have the least priority.
    def prepend_path(path)
      @paths.unshift(File.expand_path(path, root))
    end

    # Append a `path` to the `paths` list.
    #
    # Paths at the beginning of the `Array` have a higher priority.
    def append_path(path)
      @paths.push(File.expand_path(path, root))
    end

    # Clear all paths and start fresh.
    #
    # There is no mechanism for reordering paths, so its best to
    # completely wipe the paths list and reappend them in the order
    # you want.
    def clear_paths
      @paths.clear
    end

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
      name, extname, _ = parse_path_extnames(path)
      format_content_type = mime_type_for_extname(extname) if extname
      content_type = options[:content_type] || format_content_type

      if format_content_type && format_content_type != content_type
        return
      end

      if absolute_path?(path)
        resolve_absolute_path(path, name, extname, content_type, &block)
      else
        resolve_all_logical_paths(name, extname, content_type, &block)
      end

      nil
    end

    # Public: Enumerate over all logical paths in the environment.
    #
    # Returns an Enumerator of [logical_path, filename].
    def logical_paths
      return to_enum(__method__) unless block_given?

      seen = Set.new
      each_file do |filename|
        logical_path = logical_path_for(filename)
        if !seen.include?(logical_path)
          yield logical_path, filename
          seen << logical_path
        end
      end

      nil
    end
    alias_method :each_logical_path, :logical_paths

    protected
      # Internal: Reverse guess logical path for fully expanded path.
      #
      # This has some known issues. For an example if a file is
      # shaddowed in the path, but is required relatively, its logical
      # path will be incorrect.
      #
      # TODO: Review API and performance
      def logical_path_for(filename)
        # TODO: Review performance
        _, path = paths_split(self.paths, filename)
        path, extname, _ = parse_path_extnames(path)
        path = path.sub(/\/index$/, '') if File.basename(path) == 'index'
        path += extname if extname
        path
      end

      # Internal: Resolve absolute path to ensure it exists and is in the
      # load path.
      #
      # filename - String
      # options  - Hash (default: {})
      #
      # Returns String filename or nil
      def resolve_absolute_path(filename, name, extname, content_type, &block)
        return unless paths_split(self.paths, filename)

        # TODO: Review for correctness
        stat = self.stat(filename)
        if stat && stat.file?
          yield filename
        end

        path_matches(File.dirname(filename), File.basename(name), content_type, &block)
      end

      def path_matches(dirname, basename, content_type)
        self.entries(dirname).each do |entry|
          # TODO: Review performance
          name = parse_path_extnames(entry)[0]
          if basename == name
            filename = File.join(dirname, entry)
            if has_asset?(filename, accept: content_type)
              yield filename
            end
          end
        end
      end

      # Internal: Resolve logical path in load paths.
      #
      # logical_path - String
      # options      - Hash (default: {})
      # block
      #   filename - String or nil
      #
      # Returns nothing.
      def resolve_all_logical_paths(name, extname, content_type, &block)
        dirname, basename = File.split(name)
        basename_extname = "#{basename}#{extname}" if extname

        @paths.each do |base_path|
          path_dirname = File.expand_path(dirname, base_path)
          path_name    = File.expand_path(name, base_path)

          if basename_extname
            path_matches(path_dirname, basename_extname, content_type, &block)
          end

          path_matches(path_dirname, basename, content_type, &block)

          resolve_alternates(base_path, name).each do |filename|
            if has_asset?(filename, accept: content_type)
              yield filename
            end
          end

          path_matches(path_name, "index", content_type, &block)
        end
      end

      def resolve_alternates(base_path, logical_name)
        []
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
