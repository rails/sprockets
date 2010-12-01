require 'yaml'

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

    def compat?
      @compat
    end

    # LEGACY
    def constants
      root_path = environment.paths.detect { |path| source_file.path[path] }
      path = File.join(root_path, "constants.yml")
      File.exist?(path) ? YAML.load_file(path) : {}
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

    def process_require_directive(path)
      if @compat
        if path =~ /<([^>]+)>/
          path = $1
        else
          path = "./#{path}" unless relative?(path)
        end
      end

      extensions = File.basename(path).scan(/\.[^.]+/)
      path = "#{path}#{format_extension}" if extensions.empty?
      required_pathnames << resolve(path)
    end

    def process_require_tree_directive(path = ".")
      if relative?(path)
        each_pathname_in_tree(path) do |pathname|
          required_pathnames << pathname
        end
      else
        raise ArgumentError, "require_tree argument must be a relative path"
      end
    end

    def process_provide_directive(path)
      # TODO
    end

    def each_pathname_in_tree(path)
      root = File.expand_path(File.join(base_path, path))
      Dir[root + "/**/*"].sort.each do |filename|
        next unless File.file?(filename)
        pathname = Pathname.new(filename)
        yield pathname if pathname.format_extension == format_extension
      end
    end

    def relative?(path)
      path =~ /^\.($|\.?\/)/
    end

    def resolve(path)
      environment.resolve(path, :base_path => base_path)
    end

    def base_path
      source_file.pathname.dirname
    end

    def format_extension
      source_file.pathname.format_extension
    end
  end
end
