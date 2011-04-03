require "shellwords"

module Sprockets
  class DirectiveParser
    attr_reader :source, :header, :body

    HEADER_PATTERN = /
      \A \s* (
        (\/\* ([\s\S]*?) \*\/) |
        (\#\#\# ([\s\S]*?) \#\#\#) |
        (\/\/ ([^\n]*) \n?)+ |
        (\# ([^\n]*) \n?)+
      )
    /mx

    DIRECTIVE_PATTERN = /
      ^ [\W]* = \s* (\w+.*?) (\*\/)? $
    /x

    def initialize(source)
      @source = source
      @header = @source[HEADER_PATTERN, 0] || ""
      @body   = $' || @source
    end

    def header_lines
      @header_lines ||= header.split("\n")
    end

    def processed_header
      header_lines.reject do |line|
        extract_directive(line)
      end.join("\n")
    end

    def processed_source
      @processed_source ||= processed_header + body
    end

    def directives
      @directives ||= header_lines.map do |line|
        if directive = extract_directive(line)
          Shellwords.shellwords(directive)
        end
      end.compact
    end

    def extract_directive(line)
      line[DIRECTIVE_PATTERN, 1]
    end
  end
end
