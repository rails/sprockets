module Sprockets
  module Digest
    # Returns a `Digest` implementation class.
    #
    # Defaults to `Digest::MD5`.
    def digest_class
      @digest_class
    end

    # Assign a `Digest` implementation class. This maybe any Ruby
    # `Digest::` implementation such as `Digest::MD5` or
    # `Digest::SHA1`.
    #
    #     environment.digest_class = Digest::SHA1
    #
    def digest_class=(klass)
      expire_index!
      @digest_class = klass
    end

    # The `Environment#version` is a custom value used for manually
    # expiring all asset caches.
    #
    # Sprockets is able to track most file and directory changes and
    # will take care of expiring the cache for you. However, its
    # impossible to know when any custom helpers change that you mix
    # into the `Context`.
    #
    # It would be wise to increment this value anytime you make a
    # configuration change to the `Environment` object.
    def version
      @version
    end

    # Assign an environment version.
    #
    #     environment.version = '2.0'
    #
    def version=(prefix)
      expire_index!
      @version = prefix
    end

    # Returns a `Digest` instance for the `Environment`.
    #
    # This value serves two purposes. If two `Environment`s have the
    # same digest value they can be treated as equal. This is more
    # useful for comparing environment states between processes rather
    # than in the same. Two equal `Environment`s can share the same
    # cached assets.
    #
    # The value also provides a seed digest for all `Asset`
    # digests. Any change in the environment digest will affect all of
    # its assets.
    def digest
      # Recompute digest for the first time or again after its been cleared
      @digest ||= compute_digest

      # Returned a dupped copy so the caller can safely mutate it with `.update`
      @digest.dup
    end

    protected
      def compute_digest
        # Compute the initial digest using the implementation
        # class. The Sprockets release version and custom environment
        # version are mixed in.
        digest_class.new.update(VERSION).update(version.to_s)
      end
  end
end
