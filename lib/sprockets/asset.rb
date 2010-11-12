module Sprockets
  class Asset
    attr_reader :environment, :source_files, :source

    def initialize(environment, source_file)
      @environment  = environment
      @source_files = []
      @source       = ""
      require(source_file)
    end

    def require(source_file)
      unless source_files.include?(source_file)
        source_files << source_file
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
  end
end
