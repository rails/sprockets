module Sprockets
  module Paths
    # Returns `Environment` root.
    #
    # All relative paths are expanded with root as its base. To be
    # useful set this to your applications root directory. (`Rails.root`)
    def root
      @trail.root.dup
    end

    # Returns an `Array` of path `String`s.
    #
    # These paths will be used for asset logical path lookups.
    #
    # Note that a copy of the `Array` is returned so mutating will
    # have no affect on the environment. See `append_path`,
    # `prepend_path`, and `clear_paths`.
    def paths
      @trail.paths.dup
    end

    # Prepend a `path` to the `paths` list.
    #
    # Paths at the end of the `Array` have the least priority.
    def prepend_path(path)
      @trail.prepend_path(path)
    end

    # Append a `path` to the `paths` list.
    #
    # Paths at the beginning of the `Array` have a higher priority.
    def append_path(path)
      @trail.append_path(path)
    end

    # Clear all paths and start fresh.
    #
    # There is no mechanism for reordering paths, so its best to
    # completely wipe the paths list and reappend them in the order
    # you want.
    def clear_paths
      @trail.paths.dup.each { |path| @trail.remove_path(path) }
    end

    # Returns an `Array` of extensions.
    #
    # These extensions maybe omitted from logical path searches.
    #
    #     # => [".js", ".css", ".coffee", ".sass", ...]
    #
    def extensions
      @trail.extensions.dup
    end

    # Works like `Dir.entries`.
    #
    # Subclasses may cache this method.
    def entries(filename)
      @trail.entries(filename)
    end

    # Works like `File.stat`.
    #
    # Subclasses may cache this method.
    def stat(path)
      @trail.stat(path)
    end

    # Recursive stat all the files under a directory.
    #
    # root  - A String directory
    # block - Block called for each entry
    #   path - String filename
    #   stat - File::Stat
    #
    # Returns nothing.
    def recursive_stat(root, &block)
      return to_enum(__method__, root) unless block_given?

      entries(root).sort.each do |filename|
        path = File.join(root, filename)
        next unless stat = self.stat(path)
        yield path, stat

        if stat.directory?
          recursive_stat(path, &block)
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

      if Pathname.new(path).absolute?
        if filename = resolve_absolute_path(path, options)
          yield filename
        end
      else
        resolve_all_logical_paths(path, options, &block)
      end

      nil
    end

    def find_logical_paths(*args, &block)
      return to_enum(__method__, *args) unless block_given?
      filters = args.flatten
      files = {}

      paths.each do |root|
        recursive_stat(root).each do |path, stat|
          next unless stat.file?

          if logical_path = logical_path_for_filename(path, filters)
            unless files[logical_path]
              if block.arity == 2
                yield logical_path, path.to_s
              else
                yield logical_path
              end
            end

            files[logical_path] = true
          end
        end
      end
      nil
    end

    protected
      attr_reader :trail

      # Internal: Resolve absolute path to ensure it exists and is in the
      # load path.
      #
      # filename - String
      # options  - Hash (default: {})
      #
      # Returns String filename or nil
      def resolve_absolute_path(filename, options = {})
        content_type = options[:content_type]

        if paths.detect { |path| filename[path] }
          if stat(filename)
            if content_type.nil? || content_type == content_type_of(filename)
              return filename
            end
          end
        end
      end

      # Internal: Resolve logical path in trail load paths.
      #
      # logical_path - String
      # options      - Hash (default: {})
      # block
      #   filename - String or nil
      #
      # Returns nothing.
      def resolve_all_logical_paths(logical_path, options = {})
        content_type = options[:content_type]
        extension = attributes_for(logical_path).format_extension
        content_type_extension = extension_for_mime_type(content_type)

        paths = [logical_path]

        path_without_extension = extension ?
          logical_path.sub(extension, '') :
          logical_path

        # optimization: bower.json can only be nested one level deep
        if !path_without_extension.index('/')
          paths << File.join(path_without_extension, "bower.json")
        end

        paths << File.join(path_without_extension, "index#{extension}")

        @trail.find_all(*paths, options).each do |path|
          if File.basename(logical_path) != 'bower.json'
            path = expand_bower_path(path, extension || content_type_extension) || path
          end

          if content_type.nil? || content_type == content_type_of(path)
            yield path
          end
        end
      end

      def logical_path_for_filename(filename, filters)
        logical_path = logical_path_for(filename)

        if matches_filter(filters, logical_path, filename)
          return logical_path
        end

        # If filename is an index file, retest with alias
        if File.basename(logical_path)[/[^\.]+/, 0] == 'index'
          path = logical_path.sub(/\/index\./, '.')
          if matches_filter(filters, path, filename)
            return path
          end
        end

        nil
      end

      def matches_filter(filters, logical_path, filename)
        return true if filters.empty?

        filters.any? do |filter|
          if filter.is_a?(Regexp)
            filter.match(logical_path)
          elsif filter.respond_to?(:call)
            if filter.arity == 1
              filter.call(logical_path)
            else
              filter.call(logical_path, filename.to_s)
            end
          else
            File.fnmatch(filter.to_s, logical_path)
          end
        end
      end
  end
end
