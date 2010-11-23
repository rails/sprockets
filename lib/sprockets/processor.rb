module Sprockets
  class Processor
    attr_reader :environment, :source_file
    attr_reader :included_pathnames, :required_pathnames

    def initialize(environment, source_file)
      @environment        = environment
      @source_file        = source_file
      @included_pathnames = []
      @required_pathnames = []
      process_directives
    end

    def process_directives
      source_file.directives.each do |name, *args|
        send("process_#{name}_directive", *args)
      end
    end

    def process_include_directive(path)
      included_pathnames << environment.resolve(path)
    end

    def process_require_all_directive(path)
      # ?!?@?!@?!?!?!
    end

    def process_require_directive(path)
      extensions = path.scan(/\.[^.]+/)
      path = "#{path}#{source_file.format_extension}" if extensions.empty?
      required_pathnames << environment.resolve(path)
    end
  end
end
