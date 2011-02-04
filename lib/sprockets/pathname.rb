require 'rack/mime'
require 'tilt'

module Sprockets
  class Pathname
    attr_reader :path, :dirname, :basename

    def self.new(path)
      path.is_a?(self) ? path : super(path)
    end

    def initialize(path)
      @path = File.expand_path(path)
      @dirname, @basename = File.split(@path)
    end

    def extensions
      @extensions ||= basename.scan(/\.[^.]+/)
    end

    def format_extension
      if (ext = extensions.first) && Rack::Mime.mime_type(ext, nil)
        ext
      end
    end

    def engine_extensions
      offset = format_extension ? 1 : 0
      extensions[offset..-1] || []
    end

    def engines
      engine_extensions.map { |extension| Tilt[extension] }
    end

    def content_type
      @content_type ||= Rack::Mime.mime_type(format_extension)
    end

    def to_s
      @path
    end
  end
end
