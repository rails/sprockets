require 'digest/md5'
require 'fileutils'
require 'pathname'

module Sprockets
  module Cache
    # A simple file system cache store.
    #
    #     environment.cache = Sprockets::Cache::FileStore.new("tmp/sprockets")
    #
    class FileStore
      def initialize(root)
        @root = Pathname.new(root)

        # Ensure directory exists
        FileUtils.mkdir_p @root
      end

      # Lookup value in cache
      def [](key)
        pathname = path_for(key)
        pathname.exist? ? pathname.open('rb') { |f| Marshal.load(f) } : nil
      end

      # Save value to cache
      def []=(key, value)
        path_for(key).open('w') { |f| Marshal.dump(value, f)}
        value
      end

      private
        # Returns path for cache key.
        #
        # The key may include some funky characters so hash it into
        # safe hex.
        def path_for(key)
          @root.join(::Digest::MD5.hexdigest(key))
        end
    end
  end
end
