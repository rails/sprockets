require 'fileutils'
require 'logger'
require 'sprockets/encoding_utils'
require 'sprockets/path_utils'
require 'sprockets/cache/memory_store'
require 'zlib'

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
    class KFileStore
      # Internal: Default key limit for store.
      DEFAULT_MAX_SIZE = 25000

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
        start_time = Time.now
        @root = root
        @max_size = max_size
        @gc_size = max_size * 0.75
        @mem_store = Sprockets::Cache::MemoryStore.new(max_size)
        @logger = logger
        @size = find_caches.size
        load_time = Time.now.to_f - start_time.to_f
        puts "Sprockets KFile Cache - max entries: #{@max_size}, current entries: #{@size}, init time: #{(load_time * 1000).to_i}ms"
      end

      # Public: Retrieve value from cache.
      #
      # This API should not be used directly, but via the Cache wrapper API.
      #
      # key - String cache key.
      #
      # Returns Object or nil or the value is not set.
      def get(key)
        value = @mem_store.get(key)

        if value.nil?
          path = File.join(@root, "#{expand_key(key)}.cache")
          value = safe_touch_open(path) do |f|
            begin
              EncodingUtils.unmarshaled_deflated(f.read, Zlib::MAX_WBITS)
            rescue Exception => e
              @logger.error do
                "#{self.class}[#{path}] could not be unmarshaled: " +
                  "#{e.class}: #{e.message}"
              end
              nil
            end
          end
          @mem_store.set(key, value) unless value.nil?
        elsif !value.nil?
          FileUtils.touch(File.join(@root, "#{expand_key(key)}.cache"))
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
        path = File.join(@root, "#{expand_key(key)}.cache")

        # Ensure directory exists
        FileUtils.mkdir_p File.dirname(path)

        # Check if cache exists before writing
        exists = File.exist?(path)

        # Serialize value
        marshaled = Marshal.dump(value)

        # Compress if larger than 4KB
        if marshaled.bytesize > 4 * 1024
          deflater = Zlib::Deflate.new(
            Zlib::BEST_COMPRESSION,
            Zlib::MAX_WBITS,
            Zlib::MAX_MEM_LEVEL,
            Zlib::DEFAULT_STRATEGY
          )
          deflater << marshaled
          raw = deflater.finish
        else
          raw = marshaled
        end

        # Write data
        PathUtils.atomic_write(path) do |f|
          f.write(raw)
         @size += 1 unless exists
        end

        @mem_store.set(key, value)

        # GC if necessary
        gc! if @size > @max_size

        value
      end

      # Public: Pretty inspect
      #
      # Returns String.
      def inspect
        "#<#{self.class} size=#{size}/#{@max_size}>"
      end

      private

      # Internal: Expand object cache key into a short String key.
      #
      # The String should be under 250 characters so its compatible with
      # Memcache.
      #
      # key - JSON serializable key
      #
      # Returns a String with a length less than 250 characters.
      def expand_key(key)
        digest_key = DigestUtils.pack_urlsafe_base64digest(DigestUtils.digest(key))
        namespace = digest_key[0, 2]
        "sprockets/v#{VERSION}/#{namespace}/#{digest_key}"
      end

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

      def safe_mtime(fn)
        File.mtime(fn)
      rescue Errno::ENOENT
        nil
      end

      def safe_stat(fn)
        File.stat(fn)
      rescue Errno::ENOENT
        nil
      end

      def safe_touch_open(path, &block)
        if File.exist?(path)
          FileUtils.touch(path)
          File.open(path, 'rb', &block)
        end
      rescue Errno::ENOENT
        nil
      end

      def gc!
        start_time = Time.now

        caches = find_caches
        size = caches.size

        delete_caches, keep_caches = caches.partition { |_, stat|
          deleted = size > @gc_size
          size -= 1
          deleted
        }

        return if delete_caches.empty?

        FileUtils.remove(delete_caches.map(&:first), force: true)
        @size = keep_caches.size

        @logger.warn do
          secs = Time.now.to_f - start_time.to_f
          "#{self.class}[#{@root}] garbage collected " +
            "#{delete_caches.size} files (#{(secs * 1000).to_i}ms)"
        end
      end
    end
  end
end
