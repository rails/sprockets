module Sprockets
  class Processor
    attr_reader :environment, :source_file
    attr_reader :included_pathnames, :required_pathnames

    def initialize(environment, source_file)
      @environment        = environment
      @source_file        = source_file
      @included_pathnames = []
      @required_pathnames = []
      @compat             = false
      process_directives
    end

    def process_directives
      source_file.directives.each do |name, *args|
        send("process_#{name}_directive", *args)
      end
    end

    def process_compat_directive
      @compat = true
    end

    def process_include_directive(path)
      included_pathnames << resolve(path)
    end

    def process_require_all_directive(path)
      # ?!?@?!@?!?!?!
    end

    def process_require_directive(path)
      if @compat
        if path =~ /<([^>]+)>/
          path = $1
        else
          path = "./#{path}" unless path =~ /^\./
        end
      end

      extensions = File.basename(path).scan(/\.[^.]+/)
      path = "#{path}#{source_file.pathname.format_extension}" if extensions.empty?
      required_pathnames << resolve(path)
    end

    def process_provide_directive(path)
      # TODO
    end

    def resolve(path)
      environment.resolve(path, :base_path => source_file.pathname.dirname)
    end
  end
end
