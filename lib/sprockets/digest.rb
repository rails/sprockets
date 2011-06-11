module Sprockets
  module Digest
    def self.included(base)
      base.instance_eval do
        attr_reader :digest_class, :digest_key_prefix
      end
    end

    def digest_class=(klass)
      expire_index!
      @digest_class = klass
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
