require 'rack/mime'

module Sprockets
  class Pathname
    attr_reader :path, :dirname, :basename

    def self.new(path)
      path.is_a?(self) ? path : super(path)
    end

    def initialize(path)
      @path = path.to_s
      @dirname, @basename = File.split(@path)
    end

    def eql?(other)
      other.class == self.class && other.path == self.path
    end
    alias_method :==, :eql?

    def exist?
      File.exist?(path)
    end

    def file?
      File.file?(path)
    end

    def basename_without_extensions
      File.basename(basename, extensions.join)
    end

    def extensions
      @extensions ||= basename.scan(/\.[^.]+/)
    end

    def format_extension
      extensions.detect { |ext| lookup_mime_type(ext) }
    end

    def engine_extensions
      exts = extensions

      if offset = extensions.index(format_extension)
        exts = extensions[offset+1..-1]
      end

      exts.select { |ext| Environment.lookup_engine(ext) }
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
      path
    end

    def fingerprint
      if defined? @fingerprint
        @fingerprint
      elsif basename_without_extensions =~ /-([0-9a-f]{7,40})$/
        @fingerprint = $1
      else
        @fingerprint = nil
      end
    end

    def with_fingerprint(digest)
      if fingerprint
        path = self.path.sub(fingerprint, digest)
      else
        basename = "#{basename_without_extensions}-#{digest}#{extensions.join}"
        path = dirname == '.' ? basename : File.join(dirname, basename)
      end

      self.class.new(path)
    end

    private
      def lookup_mime_type(ext)
        Rack::Mime.mime_type(ext, nil)
      end
  end
end
