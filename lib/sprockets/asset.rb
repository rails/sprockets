require "digest/md5"
require "tilt"

module Sprockets
  class Asset
    attr_reader :environment, :source_paths, :source

    def initialize(environment, source_file)
      @environment  = environment
      @source_paths = []
      @source       = ""
      require(source_file)
    end

    def require(source_file)
      unless source_paths.include?(source_file.path)
        source_paths << source_file.path
        source << process(source_file)
      end
    end

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

      processor.required_files.each { |file| require(file) }
      result << source_file.header
      processor.included_files.each { |file| result << process(file) }
      result << source_file.body

      result
    end

    def each
      yield source
    end

    def length
      source.length
    end

    def content_type
      'application/javascript'
    end

    # TODO
    def md5
      Digest::MD5.hexdigest(source)
    end

    def etag
      %("#{md5}")
    end

    # TODO
    def created_at
      Time.now
    end

    # TODO
    def stale?
      true
    end

    def empty?
      source == ""
    end
  end
end
