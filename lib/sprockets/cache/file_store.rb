require 'digest/md5'
require 'fileutils'
require 'logger'
require 'tempfile'

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
    class FileStore
      # Internal: Default key limit for store.
      DEFAULT_MAX_SIZE = 25 * 1024 * 1024

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
      def initialize(root, max_size = DEFAULT_MAX_SIZE, logger = self.class.default_logger)
        @root     = root
        @size     = find_caches.inject(0) { |n, (_, stat)| n + stat.size }
        @max_size = max_size
        @gc_size  = max_size * 0.75
        @logger   = logger
        @tmpdir   = Dir.tmpdir
      end

      # Public: Retrieve value from cache.
      #
      # This API should not be used directly, but via the Cache wrapper API.
      #
      # key - String cache key.
      #
      # Returns Object or nil or the value is not set.
      def get(key)
        path = File.join(@root, "#{key}.cache")

        if File.exist?(path)
          value = File.open(path, 'rb') do |f|
            begin
              Marshal.load(f)
            rescue Exception => e
              @logger.error do
                "#{self.class}[#{path}] could not be unmarshaled: " +
                  "#{e.class}: #{e.message}"
              end
              nil
            end
          end
          FileUtils.touch(path)
          value
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
        path = File.join(@root, "#{key}.cache")

        # Ensure directory exists
        FileUtils.mkdir_p File.dirname(path)

        # Check if cache exists before writing
        exists = File.exist?(path)

        # Write data
        PathUtils.atomic_write(path, @tmpdir) do |f|
          Marshal.dump(value, f)
          @size += f.size unless exists
        end

        # GC if necessary
        gc! if @size > @max_size

        value
      end

      # Public: Pretty inspect
      #
      # Returns String.
      def inspect
        "#<#{self.class} size=#{@size}/#{@max_size}>"
      end

      private
        # Internal: Get all cache files along with stats.
        #
        # Returns an Array of [String filename, File::Stat] pairs sorted by
        # mtime.
        def find_caches
          Dir.glob(File.join(@root, '**/*.cache')).reduce([]) { |stats, filename|
            stat = safe_stat(filename)
            # stat maybe nil if file was removed between the time we called
            # dir.glob and the next stat
            stats << [filename, stat] if stat
            stats
          }.sort_by { |_, stat| stat.mtime.to_i }
        end

        def compute_size(caches)
          caches.inject(0) { |sum, (_, stat)| sum + stat.size }
        end

        def safe_stat(fn)
          File.stat(fn)
        rescue Errno::ENOENT
          nil
        end

        def gc!
          start_time = Time.now

          caches = find_caches
          size = compute_size(caches)

          delete_caches, keep_caches = caches.partition { |filename, stat|
            deleted = size > @gc_size
            size -= stat.size
            deleted
          }

          return if delete_caches.empty?

          FileUtils.remove(delete_caches.map(&:first), force: true)
          @size = compute_size(keep_caches)

          @logger.warn do
            secs = Time.now.to_f - start_time.to_f
            "#{self.class}[#{@root}] garbage collected " +
              "#{delete_caches.size} files (#{(secs * 1000).to_i}ms)"
          end
        end
    end
  end
end
