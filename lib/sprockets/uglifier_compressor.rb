module Sprockets
  class UglifierCompressor
    def self.call(input)
      require 'uglifier' unless defined? ::Uglifier

      data = input[:data]

      # Feature detect Uglifier 2.0 option support
      if Uglifier::DEFAULTS[:copyright]
        # Uglifier < 2.x
        Uglifier.new(copyright: false).compile(data)
      else
        # Uglifier >= 2.x
        Uglifier.new(comments: :none).compile(data)
      end
    end
  end
end
