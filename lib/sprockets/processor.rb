module Sprockets
  class Processor
    class ContentTypeMismatch < Error; end

    attr_reader :environment, :source_file
    attr_reader :included_files, :required_files

    def initialize(environment, source_file)
      @environment    = environment
      @source_file    = source_file
      @included_files = []
      @required_files = []
      process_directives
    end

    def process_directives
      source_file.directives.each do |name, *args|
        send("process_#{name}_directive", *args)
      end
    end

    def process_include_directive(path)
      included_files << environment.find_source_file(path)
    end

    def process_require_all_directive(path)
      # ?!?@?!@?!?!?!
    end

    def process_require_directive(path)
      ext = File.extname(path)
      if ext == ""
        path = "#{path}#{source_file.format_extension}"
      elsif ext != source_file.format_extension
        raise ContentTypeMismatch, "#{source_file.path} is " +
          "'#{source_file.format_extension}', but tried to require '#{ext}'"
      end

      required_files << environment.find_source_file(path)
    end
  end
end
