require 'pathname'
require 'rack/mime'
require 'sprockets/template_mappings'
require 'sprockets/utils'

module Sprockets
  class EnginePathname < ::Pathname
    def self.new(path)
      path.kind_of?(self) ? path : super(path)
    end

    def basename_without_extensions
      basename(extensions.join)
    end

    def extensions
      @extensions ||= basename.to_s.scan(/\.[^.]+/)
    end

    def format_extension
      extensions.detect { |ext| lookup_mime_type(ext) }
    end

    def engine_extensions
      exts = extensions

      if offset = extensions.index(format_extension)
        exts = extensions[offset+1..-1]
      end

      exts.select { |ext| TemplateMappings.lookup_engine(ext) }
    end

    def engines
      engine_extensions.map { |ext| TemplateMappings.lookup_engine(ext) }
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

    def without_engine_extensions
      engine_extensions.inject(self) do |pathname, ext|
        pathname.sub(ext, '')
      end
    end

    private
      def lookup_mime_type(ext)
        Rack::Mime.mime_type(ext, nil)
      end
  end
end
