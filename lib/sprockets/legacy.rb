require 'sprockets/manifest'

module Sprockets
  module Legacy
    # Deprecated: Iterate over all logical paths with a matcher.
    #
    # Remove from 4.x.
    #
    # args - List of matcher objects.
    #
    # Returns Enumerator if no block is given.
    def each_logical_path(*args, &block)
      return to_enum(__method__, *args) unless block_given?

      filters = args.flatten.map { |arg| Manifest.compile_match_filter(arg) }
      logical_paths.each do |a, b|
        if filters.any? { |f| f.call(a, b) }
          if block.arity == 2
            yield a, b
          else
            yield a
          end
        end
      end

      nil
    end

    # Deprecated: Enumerate over all logical paths in the environment.
    #
    # Returns an Enumerator of [logical_path, filename].
    def logical_paths
      return to_enum(__method__) unless block_given?

      seen = Set.new

      self.paths.each do |load_path|
        stat_tree(load_path).each do |filename, stat|
          next unless stat.file?

          path = split_subpath(load_path, filename)
          path, mime_type, _ = parse_path_extnames(path)
          path = normalize_logical_path(path)
          path += mime_types[mime_type][:extensions].first if mime_type

          if !seen.include?(path)
            yield path, filename
            seen << path
          end
        end
      end

      nil
    end

    def cache_get(key)
      cache._get(key)
    end

    def cache_set(key, value)
      cache._set(key, value)
    end

    private
      # Deprecated: Seriously.
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

      # URI.unescape is deprecated on 1.9. We need to use URI::Parser
      # if its available.
      if defined? URI::DEFAULT_PARSER
        def unescape(str)
          str = URI::DEFAULT_PARSER.unescape(str)
          str.force_encoding(Encoding.default_internal) if Encoding.default_internal
          str
        end
      else
        def unescape(str)
          URI.unescape(str)
        end
      end
  end
end
