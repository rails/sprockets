require 'base64'
require 'digest/sha2'

module Sprockets
  module DigestUtils
    extend self

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # obj - A JSON serializable object.
    #
    # Returns a String SHA256 digest of the object.
    def hexdigest(obj)
      digest = Digest::SHA256.new
      queue  = [obj]

      while queue.length > 0
        obj = queue.shift
        klass = obj.class

        if klass == String
          digest << 'String'
          digest << obj
        elsif klass == Symbol
          digest << 'Symbol'
          digest << obj.to_s
        elsif klass == Fixnum
          digest << 'Fixnum'
          digest << obj.to_s
        elsif klass == TrueClass
          digest << 'TrueClass'
        elsif klass == FalseClass
          digest << 'FalseClass'
        elsif klass == NilClass
          digest << 'NilClass'
        elsif klass == Array
          digest << 'Array'
          queue.concat(obj)
        elsif klass == Hash
          digest << 'Hash'
          queue.concat(obj.sort)
        elsif klass == Set
          digest << 'Set'
          queue.concat(obj.to_a)
        elsif klass == Encoding
          digest << 'Encoding'
          digest << obj.name
        else
          raise TypeError, "couldn't digest #{klass}"
        end
      end

      digest.hexdigest
    end

    # Internal: Generate a "named information" URI for use in the `integrity`
    # attribute of an asset tag as per the subresource integrity specification.
    #
    # digest       - The String byte digest of the asset content.
    # content_type - The content-type the asset will be served with. This *must*
    #                be accurate if provided. Otherwise, subresource integrity
    #                will block the loading of the asset.
    #
    # Returns a String.
    def integrity_uri(digest, content_type = nil)
      # Prepare/format the digest.
      digest = Base64.urlsafe_encode64(digest).sub(/=*\z/, "")

      # Prepare/format the query section.
      query = "?ct=#{content_type}" if content_type

      # Build the URI.
      "ni:///sha-256;#{digest}#{query}"
    end
  end
end
