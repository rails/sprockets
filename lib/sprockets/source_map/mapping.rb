module Sprockets
  class SourceMap
    class Mapping < Struct.new(:source, :generated, :original, :name)
      # Public: Get a simple string representation of the mapping.
      #
      # Returns a String.
      def to_s
        str = "#{generated[0]}:#{generated[1]}"
        str << "->#{source}@#{original[0]}:#{original[1]}"
        str << "##{name}" if name
        str
      end
    end
  end
end
