require 'tilt'

module Sprockets
  class CharsetNormalizer < Tilt::Template
    def prepare
    end

    def evaluate(context, locals, &block)
      charset = nil

      filtered_data = data.gsub(/^@charset "([^"]+)";$/) {
        charset ||= $1; ""
      }

      if charset
        "@charset \"#{charset}\";#{filtered_data}"
      else
        data
      end
    end
  end
end
