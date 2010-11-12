module Sprockets
  class SourceFile
    attr_reader :path

    def initialize(path)
      @path = path
      @raw_source = IO.read(path).gsub(/\r?\n/, "\n")
    end

    def eql?(source_file)
      path.eql?(source_file.path)
    end

    def basename
      @basename ||= File.basename(path)
    end

    def extensions
      @extensions ||= basename.scan(/\.[^.]+/)
    end

    def format_extension
      extensions.first
    end

    def engine_extensions
      extensions[1..-1].reverse
    end

    def content_type
      @content_type ||= begin
        type = Rack::Mime.mime_type(format_extension)
        type[/^text/] ? "#{type}; charset=utf-8" : type
      end
    end

    def directive_parser
      @directive_parser ||= DirectiveParser.new(@raw_source)
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
