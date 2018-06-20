module Sprockets
  module CachedDigestUtils
    extend self

    def cached_version_digest
      version_string = defined?(version) ? version : ''

      # Compute the initial digest using the implementation class. The
      # Sprockets release version and custom environment version are
      # mixed in. So any new releases will affect all your assets.
      @cached_version_digest ||= digest_class.new.update(version_string.to_s)

      # Returned a dupped copy so the caller can safely mutate it with `.update`
      @cached_version_digest.dup
    end
  end
end
