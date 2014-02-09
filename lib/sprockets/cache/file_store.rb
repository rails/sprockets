require 'digest/md5'
require 'fileutils'
require 'pathname'

module Sprockets
  module Cache
    # A simple file system cache store.
    #
    #     environment.cache = Sprockets::Cache::FileStore.new("/tmp")
    #
    class FileStore
      DEFAULT_MAX_SIZE = 1000

      def initialize(root, max_size = DEFAULT_MAX_SIZE)
        @root = root
        @max_size = max_size
      end

      # Lookup value in cache
      def [](key)
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
      def []=(key, value)
        path = File.join(@root, "#{key}.cache")

        # Ensure directory exists
        FileUtils.mkdir_p File.dirname(path)

        # Write data
        File.open(path, 'w') { |f| Marshal.dump(value, f) }

        # GC if necessary
        gc!

        value
      end

      private
        def gc!
          caches = Dir.glob(File.join(@root, '**/*.cache'))

          # Skip if number of files is under max size
          return unless caches.size > @max_size

          caches.sort_by! { |path| -File.mtime(path).to_i }
          caches[0, (caches.size - @max_size)].each do |path|
            File.delete(path)
          end
        end
    end
  end
end
