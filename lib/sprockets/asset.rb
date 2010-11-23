require "digest/md5"
require "tilt"

module Sprockets
  class Asset
    attr_reader :environment, :content_type, :format_extension, :mtime
    attr_reader :source_paths, :source

    def self.require(environment, source_file)
      asset = new(environment, source_file.content_type, source_file.format_extension)
      asset.require(source_file)
      asset
    end

    def initialize(environment, content_type, format_extension)
      @environment      = environment
      @content_type     = content_type
      @format_extension = format_extension
      @mtime            = Time.at(0)
      @source_paths     = []
      @source           = ""
    end

    def requirable?(source_file)
      content_type == source_file.content_type
    end

    def require(source_file)
      if requirable?(source_file)
        unless source_paths.include?(source_file.path)
          source_paths << source_file.path
          source << process(source_file)
        end
      else
        raise ContentTypeMismatch, "#{source_file.path} is " +
          "'#{source_file.format_extension}', not '#{format_extension}'"
      end
    end

    def each
      yield source
    end

    def length
      source.length
    end

    def md5
      Digest::MD5.hexdigest(source)
    end

    def etag
      %("#{md5}")
    end

    def stale?
      mtime < @source_paths.map { |p| File.mtime(p) }.max
    end

    protected
      def process(source_file)
        result = process_source(source_file)
        source_file.engine_extensions.each do |extension|
          result = Tilt[extension].new { result }.render
        end
        result
      end

      def process_source(source_file)
        processor = Processor.new(environment, source_file)
        result    = ""

        if source_file.mtime > mtime
          @mtime = source_file.mtime
        end

        processor.required_files.each { |file| require(file) }
        result << source_file.header
        processor.included_files.each { |file| result << process(file) }
        result << source_file.body

        result
      end
  end
end
