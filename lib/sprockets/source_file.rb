module Sprockets
  class SourceFile
    attr_reader :pathname, :source, :mtime

    def initialize(path)
      @pathname = Pathname.new(path)
      @source   = IO.read(self.path).gsub(/\r?\n/, "\n")
      @mtime    = File.mtime(self.path)
    end

    def path
      pathname.path
    end

    def content_type
      pathname.content_type
    end

    def directive_parser
      @directive_parser ||= DirectiveParser.new(source)
    end

    def directives
      directive_parser.directives
    end

    def header
      directive_parser.processed_header
    end

    def body
      directive_parser.body
    end
  end
end
