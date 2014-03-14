module Sprockets
  class UglifierCompressor < Template
    def render(context)
      require 'uglifier' unless defined? ::Uglifier

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
