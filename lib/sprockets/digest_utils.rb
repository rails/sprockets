# frozen_string_literal: true
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'
require 'set'

module Sprockets
  # Internal: Hash functions and digest related utilities. Mixed into
  # Environment.
  module DigestUtils
    extend self

    # Internal: Default digest class.
    #
    # Returns a Digest::Base subclass.
    def digest_class
      Digest::SHA256
    end

    # Internal: Maps digest bytesize to the digest class.
    DIGEST_SIZES = {
      16 => Digest::MD5,
      20 => Digest::SHA1,
      32 => Digest::SHA256,
      48 => Digest::SHA384,
      64 => Digest::SHA512
    }

    # Internal: Detect digest class hash algorithm for digest bytes.
    #
    # While not elegant, all the supported digests have a unique bytesize.
    #
    # Returns Digest::Base or nil.
    def detect_digest_class(bytes)
      DIGEST_SIZES[bytes.bytesize]
    end

    module RefinementDigestUtils
      extend self

      module AddValueToDigest
        refine Object do
          def add_value_to_digest(_)
            raise TypeError, "couldn't digest #{self}"
          end
        end

        refine String do
          def add_value_to_digest(digest)
            digest << self
          end
        end

        refine FalseClass do
          def add_value_to_digest(digest)
            digest << 'FalseClass'.freeze
          end
        end

        refine TrueClass do
          def add_value_to_digest(digest)
            digest << 'TrueClass'.freeze
          end
        end

        refine NilClass do
          def add_value_to_digest(digest)
            digest << 'NilClass'.freeze
          end
        end

        refine Symbol do
          def add_value_to_digest(digest)
            digest << 'Symbol'.freeze
            digest << to_s
          end
        end

        refine Fixnum do
          def add_value_to_digest(digest)
            digest << 'Integer'.freeze
            digest << to_s
          end
        end

        refine Bignum do
          def add_value_to_digest(digest)
            digest << 'Integer'.freeze
            digest << to_s
          end
        end

        refine Array do
          def add_value_to_digest(digest)
            digest << 'Array'.freeze
            each do |element|
              element.add_value_to_digest(digest)
            end
          end
        end

        refine Hash do
          def add_value_to_digest(digest)
            digest << 'Hash'.freeze
            sort.each do |array|
              digest << 'Array'.freeze
              array.each do |element|
                element.add_value_to_digest(digest)
              end
            end
          end
        end

        refine Set do
          def add_value_to_digest(digest)
            digest << 'Set'.freeze
            digest << 'Array'.freeze
            each do |element|
              element.add_value_to_digest(digest)
            end
          end
        end

        refine Encoding do
          def add_value_to_digest(digest)
            digest << 'Encoding'.freeze
            digest << self.name
          end
        end
      end
      using AddValueToDigest

      def digest(digest, obj)
        obj.add_value_to_digest(digest)
        digest
      end
    end
    private_constant :RefinementDigestUtils

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # This is used for generating cache keys, so its pretty important its
    # wicked fast. Microbenchmarks away!
    #
    # obj - A JSON serializable object.
    #
    # Returns a String digest of the object.
    def digest(obj)
      build_digest(obj).digest
    end

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # The same as `pack_hexdigest(digest(obj))`.
    #
    # obj - A JSON serializable object.
    #
    # Returns a String digest of the object.
    def hexdigest(obj)
      build_digest(obj).hexdigest!
    end

    # Internal: Pack a binary digest to a hex encoded string.
    #
    # bin - String bytes
    #
    # Returns hex String.
    def pack_hexdigest(bin)
      bin.unpack('H*'.freeze).first
    end

    # Internal: Unpack a hex encoded digest string into binary bytes.
    #
    # hex - String hex
    #
    # Returns binary String.
    def unpack_hexdigest(hex)
      [hex].pack('H*')
    end

    # Internal: Pack a binary digest to a base64 encoded string.
    #
    # bin - String bytes
    #
    # Returns base64 String.
    def pack_base64digest(bin)
      [bin].pack('m0')
    end

    # Internal: Pack a binary digest to a urlsafe base64 encoded string.
    #
    # bin - String bytes
    #
    # Returns urlsafe base64 String.
    def pack_urlsafe_base64digest(bin)
      str = pack_base64digest(bin)
      str.tr!('+/'.freeze, '-_'.freeze)
      str.tr!('='.freeze, ''.freeze)
      str
    end

    # Internal: Maps digest class to the CSP hash algorithm name.
    HASH_ALGORITHMS = {
      Digest::SHA256 => 'sha256'.freeze,
      Digest::SHA384 => 'sha384'.freeze,
      Digest::SHA512 => 'sha512'.freeze
    }

    # Public: Generate hash for use in the `integrity` attribute of an asset tag
    # as per the subresource integrity specification.
    #
    # digest - The String byte digest of the asset content.
    #
    # Returns a String or nil if hash algorithm is incompatible.
    def integrity_uri(digest)
      case digest
      when Digest::Base
        digest_class = digest.class
        digest = digest.digest
      when String
        digest_class = DIGEST_SIZES[digest.bytesize]
      else
        raise TypeError, "unknown digest: #{digest.inspect}"
      end

      if hash_name = HASH_ALGORITHMS[digest_class]
        "#{hash_name}-#{pack_base64digest(digest)}"
      end
    end

    # Public: Generate hash for use in the `integrity` attribute of an asset tag
    # as per the subresource integrity specification.
    #
    # digest - The String hexbyte digest of the asset content.
    #
    # Returns a String or nil if hash algorithm is incompatible.
    def hexdigest_integrity_uri(hexdigest)
      integrity_uri(unpack_hexdigest(hexdigest))
    end

    private
      def build_digest(obj)
        digest = digest_class.new
        RefinementDigestUtils.digest(digest, obj)
      end
  end
end
