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
    class DalliStore
      # Internal: Default key limit for store.
      DEFAULT_MAX_SIZE = 40000

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
        @max_size = DEFAULT_MAX_SIZE
        @int_cache = Sprockets::Cache::IntCache.new
        puts "Sprockets Dalli Cache"
      end

      # Public: Retrieve value from cache.
      #
      # This API should not be used directly, but via the Cache wrapper API.
      #
      # key - String cache key.
      #
      # Returns Object or nil or the value is not set.
      def get(key)
        value = @int_cache.get(key)
        if value.nil?
          value = @dalli.get(key)
          @int_cache.set(key, value) unless value.nil?
        end
        value
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
        @int_cache.set(key, value)
        # GC if necessary
        @int_cache.shift if @int_cache.size > @max_size
        value
      end

      # Public: Pretty inspect
      #
      # Returns String.
      def inspect
        "#<#{self.class} size=#{@int_cache.size}/#{@max_size}>"
      end
    end
  end
end
