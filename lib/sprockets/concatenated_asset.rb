require "digest/md5"
require "json"
require "rack/utils"
require "set"
require "sprockets/context"
require "sprockets/errors"
require "sprockets/processor"
require "sprockets/source_file"
require "time"

module Sprockets
  class ConcatenatedAsset
    DEFAULT_ENGINE_EXTENSIONS = %w( .coffee .erb .less .sass .scss .str )
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    def self.concatenatable?(pathname)
      CONCATENATABLE_EXTENSIONS.include?(pathname.format_extension)
    end

    attr_reader :content_type, :format_extension
    attr_reader :mtime, :length

    def initialize(environment, pathname)
      @content_type     = pathname.content_type
      @format_extension = pathname.format_extension
      @source_paths     = Set.new
      @source           = []
      @mtime            = Time.at(0)
      @length           = 0
      @digest           = Digest::MD5.new

      require(environment, pathname)

      if content_type == 'application/javascript' && environment.js_compressor
        self.source = environment.js_compressor.compress(source.join)
      elsif content_type == 'text/css' && environment.css_compressor
        self.source = environment.css_compressor.compress(source.join)
      end
    end

    def digest
      @digest.is_a?(String) ? @digest : @digest.hexdigest
    end

    def each(&block)
      @source.each(&block)
    end

    def stale?
      @source_paths.any? { |p| mtime < File.mtime(p) }
    end

    def to_s
      @source.join
    end

    def eql?(other)
      other.class == self.class &&
        other.content_type == self.content_type &&
        other.format_extension == self.format_extension &&
        other.source_paths == self.source_paths &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      attr_reader :source_paths, :source

      def source=(str)
        @length = Rack::Utils.bytesize(str)
        @digest.update(str)
        @source = [str]
      end

      def <<(str)
        @length += Rack::Utils.bytesize(str)
        @digest << str
        @source << str
      end

      def requirable?(pathname)
        content_type == pathname.content_type
      end

      def require(environment, pathname)
        if pathname.directory?
          source_paths << pathname.to_s
        elsif requirable?(pathname)
          unless source_paths.include?(pathname.to_s)
            source_paths << pathname.to_s
            self << process(environment, pathname)
          end
        else
          raise ContentTypeMismatch, "#{pathname} is " +
            "'#{pathname.format_extension}', not '#{format_extension}'"
        end
      end

      def process(environment, pathname)
        result = process_source(environment, pathname)
        scope, locals = Context.new(environment, pathname), {}
        pathname.engines.reverse_each do |engine|
          result = engine.new(pathname.to_s) { result }.render(scope, locals)
        end
        result
      end

      def process_source(environment, pathname)
        source_file = SourceFile.new(pathname)
        processor   = Processor.new(environment, source_file)
        result      = ""

        if source_file.mtime > mtime
          @mtime = source_file.mtime
        end

        processor.required_pathnames.each { |p| require(environment, p) }
        result << source_file.header << "\n" unless source_file.header.empty?
        processor.included_pathnames.each { |p| result << process(environment, p) }
        result << source_file.body

        # LEGACY
        if processor.compat? && (constants = processor.constants).any?
          result.gsub!(/<%=(.*?)%>/) { constants[$1.strip] }
        end

        result
      end
  end
end
