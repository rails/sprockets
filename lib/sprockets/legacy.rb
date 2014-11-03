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
  end
end
