module Sprockets
  class Cache
    # Public: Simple Hash based ordered cache, for use in DB base caches
    #
    #
    class IntCache
      # Public: Initialize the cache store.
      #
      # max_size - A Integer of the maximum number of keys the store will hold.
      #            (default: 1000).
      def initialize
        @cache = {}
      end

      # Public: Retrieve value from cache.
      #
      # This API should not be used directly, but via the Cache wrapper API.
      #
      # key - String cache key.
      #
      # Returns Object or nil or the value is not set.
      def get(key)
        exists = true
        value = @cache.delete(key) { exists = false }
        if exists
          @cache[key] = value
        else
          nil
        end
      end

      # Public: Set a key and value in the cache.
      #
      # This API should not be used directly, but via the Cache wrapper API.
      #
      # key   - String cache key.
      # value - Object value.
      #
      # Returns Object value.
      def set(key, value)
        @cache.delete(key)
        @cache[key] = value
      end

      def straight_set(key, value)
        @cache[key] = value
      end

      def shift
        @cache.shift
      end

      def size
        @cache.size
      end

      # Public: Pretty inspect
      #
      # Returns String.
      def inspect
        "#<#{self.class} size=#{@cache.size}>"
      end
    end
  end
end
