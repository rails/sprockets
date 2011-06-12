module Sprockets
  module Digest
    def digest_class
      @digest_class
    end

    def digest_class=(klass)
      expire_index!
      @digest_class = klass
    end

    def digest_key_prefix
      @digest_key_prefix
    end

    def digest_key_prefix=(prefix)
      expire_index!
      @digest_key_prefix = prefix
    end

    def digest
      @digest.dup
    end

    private
      def compute_digest
        d = digest_class.new
        d << root.to_s
        d << digest_key_prefix
        d << static_root_hash
        d << paths_hash
        d << processors_hash
        d
      end
  end
end
