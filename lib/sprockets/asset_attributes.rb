module Sprockets
  # `AssetAttributes` is a wrapper similar to `Pathname` that provides
  # some helper accessors.
  #
  # These methods should be considered internalish.
  class AssetAttributes
    attr_reader :environment

    def initialize(environment, path)
      @environment = environment
      @path = path
    end

    # Returns an `Array` of engine extensions.
    #
    #     "foo.js.coffee.erb"
    #     # => [".coffee", ".erb"]
    #
    def engine_extensions
      exts = extensions

      if offset = extensions.index(@environment.format_extension_for(@path))
        exts = extensions[offset+1..-1]
      end

      exts.select { |ext| @environment.engines(ext) }
    end

    # Returns the content type for the filename. Falls back to `application/octet-stream`.
    def content_type
      @content_type ||= begin
        if @environment.format_extension_for(@path).nil?
          engine_content_type || 'application/octet-stream'
        else
          format_content_type ||
            engine_content_type ||
            'application/octet-stream'
        end
      end
    end

    private
      # Returns `Array` of extension `String`s.
      #
      #     "foo.js.coffee"
      #     # => [".js", ".coffee"]
      #
      def extensions
        @extensions ||= File.basename(@path).scan(/\.[^.]+/)
      end

      def format_content_type
        ext = @environment.format_extension_for(@path)
        ext && environment.mime_types(ext)
      end

      # Returns implicit engine content type.
      #
      # `.coffee` files carry an implicit `application/javascript`
      # content type.
      def engine_content_type
        engine_extensions.each do |ext|
          if mime_type = environment.engine_mime_types[ext]
            return mime_type
          end
        end
        nil
      end

      def engine_format_extension
        if content_type = engine_content_type
          environment.mime_types.key(content_type)
        end
      end
  end
end
