module Sprockets
  class Cache
    # Basic in memory LRU cache.
    #
    #     environment.cache = Sprockets::Cache::MemoryStore.new(1000)
    #
    # See Also
    #
    #   ActiveSupport::Cache::NullStore
    #
    class MemoryStore
      DEFAULT_MAX_SIZE = 1000

      def initialize(max_size = DEFAULT_MAX_SIZE)
        @max_size = max_size
        @cache = {}
      end

      def get(key)
        exists = true
        value = @cache.delete(key) { exists = false }
        if exists
          @cache[key] = value
        else
          nil
        end
      end

      def set(key, value)
        @cache.delete(key)
        @cache[key] = value
        @cache.shift if @cache.size > @max_size
        value
      end
    end
  end
end
