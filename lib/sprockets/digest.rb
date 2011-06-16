module Sprockets
  module Digest
    def digest_class
      @digest_class
    end

    def digest_class=(klass)
      expire_index!
      @digest_class = klass
    end

    def version
      @version
    end

    def version=(prefix)
      expire_index!
      @version = prefix
    end

    def digest
      @digest ||= compute_digest
      @digest.dup
    end

    protected
      def compute_digest
        digest_class.new.update(VERSION).update(version.to_s)
      end
  end
end
