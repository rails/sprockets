require 'pathname'

module Sprockets
  # `AssetAttributes` is a wrapper similar to `Pathname` that provides
  # some helper accessors.
  #
  # These methods should be considered internalish.
  class AssetAttributes
    attr_reader :environment, :pathname

    def initialize(environment, path)
      @environment = environment
      @pathname = path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
    end

    # Replaces `$root` placeholder with actual environment root.
    def expand_root
      pathname.to_s.sub(/^\$root/, environment.root)
    end

    # Replaces environment root with `$root` placeholder.
    def relativize_root
      pathname.to_s.sub(/^#{Regexp.escape(environment.root)}/, '$root')
    end

    # Strips `$HOME` and environment root for a nicer output.
    def pretty_path
      @pretty_path ||= @pathname.
        sub(/^#{Regexp.escape(ENV['HOME'] || '')}/, '~').
        sub(/^#{Regexp.escape(environment.root)}\//, '')
    end

    # Returns the index location.
    #
    #     "foo/bar.js"
    #     # => "foo/bar/index.js"
    #
    def index_path
      if basename_without_extensions.to_s == 'index'
        pathname.to_s
      else
        basename = "#{basename_without_extensions}/index#{extensions.join}"
        pathname.dirname.to_s == '.' ? basename : pathname.dirname.join(basename).to_s
      end
    end

    # Returns `Array` of extension `String`s.
    #
    #     "foo.js.coffee"
    #     # => [".js", ".coffee"]
    #
    def extensions
      @extensions ||= @pathname.basename.to_s.scan(/\.[^.]+/)
    end

    # Returns the format extension.
    #
    #     "foo.js.coffee"
    #     # => ".js"
    #
    def format_extension
      extensions.detect { |ext| @environment.mime_types(ext) }
    end

    # Returns an `Array` of engine extensions.
    #
    #     "foo.js.coffee.erb"
    #     # => [".coffee", ".erb"]
    #
    def engine_extensions
      exts = extensions

      if offset = extensions.index(format_extension)
        exts = extensions[offset+1..-1]
      end

      exts.select { |ext| @environment.engines(ext) }
    end

    # Returns path without any engine extensions.
    #
    #     "foo.js.coffee.erb"
    #     # => "foo.js"
    #
    def without_engine_extensions
      engine_extensions.inject(pathname) do |p, ext|
        p.sub(ext, '')
      end
    end

    # Returns engine classes.
    def engines
      engine_extensions.map { |ext| @environment.engines(ext) }
    end

    # Returns all processors to run on the path.
    def processors
      environment.preprocessors(content_type) +
        engines.reverse +
        environment.postprocessors(content_type)
    end

    # Returns implicit engine content type.
    #
    # `.coffee` files carry an implicit `application/javascript`
    # content type.
    def engine_content_type
      engines.reverse.each do |engine|
        if engine.respond_to?(:default_mime_type) && engine.default_mime_type
          return engine.default_mime_type
        end
      end
      nil
    end

    # Returns the content type for the pathname. Falls back to `application/octet-stream`.
    def content_type
      @content_type ||= begin
        if format_extension.nil?
          engine_content_type || 'application/octet-stream'
        else
          @environment.mime_types(format_extension) ||
            engine_content_type ||
            'application/octet-stream'
        end
      end
    end

    # Gets digest fingerprint.
    #
    #     "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
    #     # => "0aa2105d29558f3eb790d411d7d8fb66"
    #
    def path_fingerprint
      pathname.basename(extensions.join).to_s =~ /-([0-9a-f]{7,40})$/ ? $1 : nil
    end

    # Injects digest fingerprint into path.
    #
    #     "foo.js"
    #     # => "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
    #
    def path_with_fingerprint(digest)
      if path_fingerprint
        path.sub($1, digest)
      else
        basename = "#{pathname.basename(extensions.join)}-#{digest}#{extensions.join}"
        pathname.dirname.to_s == '.' ? basename : pathname.dirname.join(basename).to_s
      end
    end

    private
      # Returns basename alone.
      #
      #     "foo/bar.js"
      #     # => "bar"
      #
      def basename_without_extensions
        @pathname.basename(extensions.join)
      end
  end
end
