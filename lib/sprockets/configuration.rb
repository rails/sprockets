require 'sprockets/compressing'
require 'sprockets/engines'
require 'sprockets/mime'
require 'sprockets/paths'
require 'sprockets/processing'

module Sprockets
  module Configuration
    include Paths, Mime, Engines, Processing, Compressing

    private
      def deep_copy_hash(hash)
        initial = Hash.new { |h, k| h[k] = [] }
        hash.each_with_object(initial) { |(k, a),h| h[k] = a.dup }
      end
  end
end
