require 'rack/mime'

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
      if (ext = extensions.first) && lookup_mime_type(ext)
        ext
      end
    end

    def engine_extensions
      offset = format_extension ? 1 : 0
      extensions[offset..-1] || []
    end

    def engines
      engine_extensions.map { |ext| Environment.lookup_engine(ext) }
    end

    def engine_content_type
      engines.reverse.each do |engine|
        if engine.respond_to?(:default_mime_type) && engine.default_mime_type
          return engine.default_mime_type
        end
      end
      nil
    end

    def content_type
      @content_type ||= lookup_mime_type(format_extension) ||
        engine_content_type ||
        'application/octet-stream'
    end

    def to_s
      @path
    end

    private
      def lookup_mime_type(ext)
        Rack::Mime.mime_type(ext, nil)
      end
  end
end
