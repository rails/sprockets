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

    # Returns an `Array` of extensions.
    #
    # These extensions maybe omitted from logical path searches.
    #
    #     # => [".js", ".css", ".coffee", ".sass", ...]
    #
    attr_reader :extensions

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

      extnames = extensions_for(path)
      extname = extnames[:format_extname]
      format_content_type = mime_types(extname) if extname
      content_type = options[:content_type] || format_content_type

      if format_content_type && format_content_type != content_type
        return
      end

      filter_content_type = proc do |filename|
        if matches_content_type?(content_type, filename)
          yield filename
        end
      end

      if absolute_path?(path)
        resolve_absolute_path(path, &filter_content_type)
      else
        resolve_all_logical_paths(path, extnames[:name], &filter_content_type)
      end

      nil
    end

    # Public: Enumerate over all logical paths in the environment.
    #
    # Returns an Enumerator of [logical_path, filename].
    def logical_paths
      return to_enum(__method__) unless block_given?

      seen = Set.new
      self.paths.each do |root|
        stat_tree(root).each do |filename, stat|
          if stat.file?
            logical_path = logical_path_for(filename)
            if !seen.include?(logical_path)
              yield logical_path, filename
              seen << logical_path
            end
          end
        end
      end

      nil
    end

    protected
      # Internal: Reverse guess logical path for fully expanded path.
      #
      # This has some known issues. For an example if a file is
      # shaddowed in the path, but is required relatively, its logical
      # path will be incorrect.
      #
      # TODO: Review API and performance
      def logical_path_for(filename)
        _, path = paths_split(self.paths, filename)
        if path
          extnames = extensions_for(path)

          path = extnames[:name]
          path = path.sub(/\/index$/, '') if File.basename(path) == 'index'

          if extnames[:format_extname]
            path += extnames[:format_extname]
          else
            extnames[:engine_extnames].each do |eng_ext|
              if eng_mime_type = @engine_mime_types[eng_ext]
                # FIXME: Reverse mime type lookup is a smell
                path += mime_types.key(eng_mime_type)
                break
              end
            end
          end

          path
        else
          raise FileOutsidePaths, "#{filename} isn't in paths: #{self.paths.join(', ')}"
        end
      end

      # Internal: Resolve absolute path to ensure it exists and is in the
      # load path.
      #
      # filename - String
      # options  - Hash (default: {})
      #
      # Returns String filename or nil
      def resolve_absolute_path(filename, &block)
        base_path, logical_path = paths_split(self.paths, filename)
        if base_path && logical_path
          dirname, basename = File.split(filename)
          path_matches(dirname, basename, &block)
        end
      end

      def path_matches(dirname, basename)
        basename_re = Regexp.escape(basename)
        extension_pattern = @extensions.map { |e| Regexp.escape(e) }.join("|")
        pattern = /^#{basename_re}(?:#{extension_pattern})*$/

        self.entries(dirname).each do |entry|
          if entry =~ pattern
            fn = File.join(dirname, entry)
            stat = self.stat(fn)
            if stat && stat.file?
              yield fn
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
      def resolve_all_logical_paths(logical_path, path_without_extname)
        paths = [logical_path]
        paths << path_without_extname if path_without_extname != logical_path

        # optimization: bower.json can only be nested one level deep
        if !path_without_extname.index('/')
          paths << File.join(path_without_extname, "bower.json")
        end

        paths << File.join(path_without_extname, "index")

        paths.each do |path|
          dirname, basename = File.split(path)
          @paths.each do |base_path|
            path_matches(File.expand_path(dirname, base_path), basename) do |filename|
              expand_bower_path(filename) do |bower_path|
                yield bower_path
              end

              yield filename
            end
          end
        end
      end
  end
end
