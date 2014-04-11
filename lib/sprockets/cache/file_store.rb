require 'digest/md5'
require 'fileutils'
require 'pathname'

module Sprockets
  class Cache
    # A simple file system cache store.
    #
    #     environment.cache = Sprockets::Cache::FileStore.new("/tmp")
    #
    class FileStore
      DEFAULT_MAX_SIZE = 1000

      def initialize(root, max_size = DEFAULT_MAX_SIZE)
        @root = root
        @size = find_caches.size
        @max_size = max_size
      end

      # Lookup value in cache
      def get(key)
        path = File.join(@root, "#{key}.cache")

        if File.exist?(path)
          value = File.open(path, 'rb') { |f| Marshal.load(f) }
          FileUtils.touch(path)
          value
        else
          nil
        end
      end

      # Save value to cache
      def set(key, value)
        path = File.join(@root, "#{key}.cache")

        # Ensure directory exists
        FileUtils.mkdir_p File.dirname(path)

        # Check if cache exists before writing
        exists = File.exist?(path)

        # Write data
        File.open(path, 'w') { |f| Marshal.dump(value, f) }

        # GC if necessary
        @size += 1 unless exists
        gc! if @size > @max_size

        value
      end

      private
        def find_caches
          Dir.glob(File.join(@root, '**/*.cache'))
        end

        def gc!
          caches = find_caches

          new_size = @max_size * 0.75
          num_to_delete = caches.size - new_size
          return unless num_to_delete > 0

          caches.sort_by! { |path| -File.mtime(path).to_i }
          FileUtils.remove(caches[0, num_to_delete], force: true)

          @size = find_caches.size
        end
    end
  end
end
