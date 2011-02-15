require "digest/sha1"
require "json"
require "rack/utils"
require "set"
require "time"

module Sprockets
  class ConcatenatedAsset
    attr_reader :content_type, :format_extension
    attr_reader :mtime, :length

    def initialize(environment, pathname)
      @content_type     = pathname.content_type
      @format_extension = pathname.format_extension
      @source_paths     = Set.new
      @source           = []
      @mtime            = Time.at(0)
      @length           = 0
      @digest           = Digest::SHA1.new

      require(environment, pathname)
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

    def self.json_create(obj)
      allocate.tap { |asset| asset.from_json(obj) }
    end

    def from_json(obj)
      @content_type     = obj['content_type']
      @format_extension = obj['format_extension']

      @source_paths = Set.new(obj['source_paths'])
      @source       = obj['source']
      @mtime        = Time.parse(obj['mtime'])
      @length       = obj['length']
      @digest       = obj['digest']
    end

    def to_json(*args)
      {
        :json_class       => self.class.name,
        :content_type     => content_type,
        :format_extension => format_extension,
        :source_paths     => source_paths.to_a,
        :source           => source,
        :mtime            => mtime,
        :length           => length,
        :digest           => digest
      }.to_json(*args)
    end

    protected
      attr_reader :source_paths, :source

      def <<(str)
        @length += Rack::Utils.bytesize(str)
        @digest << str
        @source << str
      end

      def requirable?(pathname)
        content_type == pathname.content_type
      end

      def require(environment, pathname)
        if File.directory?(pathname.path)
          source_paths << pathname.path
        elsif requirable?(pathname)
          unless source_paths.include?(pathname.path)
            source_paths << pathname.path
            self << process(environment, pathname)
          end
        else
          raise ContentTypeMismatch, "#{pathname.path} is " +
            "'#{pathname.format_extension}', not '#{format_extension}'"
        end
      end

      def process(environment, pathname)
        result = process_source(environment, pathname)
        scope, locals = Context.new(environment, pathname), {}
        pathname.engines.reverse_each do |engine|
          result = engine.new(pathname.path) { result }.render(scope, locals)
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
