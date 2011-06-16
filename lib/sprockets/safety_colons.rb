require 'tilt'

module Sprockets
  class SafetyColons < Tilt::Template
    def prepare
    end

    def evaluate(context, locals, &block)
      if data =~ /\A\s*\Z/m || data =~ /;\s*\Z/m
        data
      else
        "#{data};"
      end
    end
  end
end
