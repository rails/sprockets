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
      digest_class.new.update(digest_key_prefix)
    end
  end
end
