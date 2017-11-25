require 'dalli'
require 'logger'
require 'sprockets/encoding_utils'
require 'sprockets/path_utils'

module Sprockets
  class Cache
    # Public: A file system cache store that automatically cleans up old keys.
    #
    # Assign the instance to the Environment#cache.
    #
    #     environment.cache = Sprockets::Cache::FileStore.new("/tmp")
    #
    # See Also
    #
    #   ActiveSupport::Cache::FileStore
    #
    class RawDalliStore
      # Internal: Default standard error fatal logger.
      #
      # Returns a Logger.
      def self.default_logger
        logger = Logger.new($stderr)
        logger.level = Logger::FATAL
        logger
      end

      # Public: Initialize the cache store.
      #
      # root     - A String path to a directory to persist cached values to.
      # max_size - A Integer of the maximum number of keys the store will hold.
      #            (default: 1000).
      def initialize(host = 'localhost', port = '11211', logger = self.class.default_logger)
        @logger = logger
        @dalli = Dalli::Client.new("#{host}:#{port}", value_max_bytes: 20 * 1024 * 1024)
        puts "Sprockets Raw Dalli Cache"
      end

      # Public: Retrieve value from cache.
      #
      # This API should not be used directly, but via the Cache wrapper API.
      #
      # key - String cache key.
      #
      # Returns Object or nil or the value is not set.
      def get(key)
        @dalli.get(key)
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
        @dalli.set(key, value)
        value
      end

      # Public: Pretty inspect
      #
      # Returns String.
      def inspect
        "#<#{self.class}>"
      end
    end
  end
end
