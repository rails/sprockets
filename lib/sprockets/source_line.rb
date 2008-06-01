module Sprockets
  class SourceLine
    attr_reader :source_file, :line, :number

    def initialize(source_file, line, number)
      @source_file = source_file
      @line = line
      @number = number
    end
    
    def comment
      @comment ||= line[/^\s*\/\/(.*)/, 1]
    end

    def comment?
      !!comment
    end

    def require
      @require ||= (comment || "")[/^=\s+require\s+(\"(.*?)\"|<(.*?)>)\s*$/, 1]
    end
    
    def require?
      !!require
    end
    
    def inspect
      "line #@number of #{@source_file.pathname}"
    end
  end
end
