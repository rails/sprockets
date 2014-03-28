module Sprockets
  class Cache
    # A compatible cache store that doesn't store anything. Used by default
    # when no Environment#cache is configured.
    #
    #     environment.cache = Sprockets::Cache::NullStore
    #
    # See Also
    #
    #   ActiveSupport::Cache::NullStore
    #
    class NullStore
      def [](key)
        nil
      end

      def []=(key, value)
        value
      end
    end
  end
end
