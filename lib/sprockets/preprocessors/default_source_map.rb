# frozen_string_literal: true
module Sprockets
  module Preprocessors
    # Private: Adds a default map to assets when one is not present
    #
    # If the input file already has a source map, it effectively returns the original
    # result. Otherwise it maps 1 for 1 lines original to generated. This is needed
    # Because other generators run after might depend on having a valid source map
    # available.
    class DefaultSourceMap
      def call(input)
        result = { data: input[:data] }
        map    = input[:metadata][:map]
        if map.nil? || map.empty?
          result[:map] ||= []
          input[:data].each_line.with_index do |_, index|
            line = index + 1
            result[:map] << { source: input[:source_path], generated: [line , 0], original: [line, 0] }
          end
        end
        return result
      end
    end
  end
end
