require 'sprockets/base'
require 'sprockets/context'
require 'sprockets/cached_environment'

module Sprockets
  class Environment < Base
    # `Environment` should initialized with your application's root
    # directory. This should be the same as your Rails or Rack root.
    #
    #     env = Environment.new(Rails.root)
    #
    def initialize(root = ".")
      @root = File.expand_path(root)

      @version = ''

      initialize_configuration(Sprockets)

      self.cache = Cache::MemoryStore.new

      yield self if block_given?
    end

    # Returns a cached version of the environment.
    #
    # All its file system calls are cached which makes `cached` much
    # faster. This behavior is ideal in production since the file
    # system only changes between deploys.
    def cached
      CachedEnvironment.new(self)
    end
    alias_method :index, :cached

    # Cache `find_asset` calls
    def find_asset(path, options = {})
      cached.find_asset(path, options)
    end
  end
end
