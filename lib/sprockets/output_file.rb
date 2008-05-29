module Sprockets
  class OutputFile
    attr_reader :source_lines
    
    def initialize
      @source_lines = []
    end
    
    def record(source_line)
      @source_lines << source_line
      source_line
    end
    
    def to_s
      @source_lines.map do |source_line|
        source_line.line
      end.join
    end
  end
end
