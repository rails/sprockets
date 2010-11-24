require 'rack/mime'

module Sprockets
  class Pathname
    attr_reader :path

    def self.new(path)
      path.is_a?(self) ? path : super(path)
    end

    def initialize(path)
      @path = File.expand_path(path)
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
      extensions[1..-1] || []
    end

    def content_type
      @content_type ||= Rack::Mime.mime_type(format_extension)
    end

    def to_s
      @path
    end
  end
end
