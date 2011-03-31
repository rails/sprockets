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
      if compat?
        root_path = environment.paths.detect { |path| source_file.path[path] }
        path = File.join(root_path, "constants.yml")
        File.exist?(path) ? YAML.load_file(path) : {}
      else
        {}
      end
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

      pathname = Pathname.new(path)
      if pathname.format_extension
        if source_file.content_type != pathname.content_type
          raise ContentTypeMismatch, "#{pathname.path} is " +
            "'#{pathname.format_extension}', not '#{source_file.pathname.format_extension}'"
        end
      end

      resolve(path) do |candidate|
        if source_file.content_type == candidate.content_type
          required_pathnames << candidate
          return
        end
      end

      raise FileNotFound, "couldn't find file '#{path}'"
    end

    def process_require_tree_directive(path = ".")
      if relative?(path)
        root = File.expand_path(File.join(base_path, path))
        required_pathnames << Pathname.new(root)

        each_pathname_in_tree(path) do |pathname|
          required_pathnames << pathname
        end
      else
        raise ArgumentError, "require_tree argument must be a relative path"
      end
    end

    def process_provide_directive(path)
      @environment.paths << File.expand_path(path, base_path)
    end

    def each_pathname_in_tree(path)
      root = File.expand_path(File.join(base_path, path))
      Dir[root + "/**/*"].sort.each do |filename|
        pathname = Pathname.new(filename)

        if File.directory?(filename)
          yield pathname
        elsif File.file?(filename) &&
            pathname.content_type == source_file.content_type
          yield pathname
        end
      end
    end

    def relative?(path)
      path =~ /^\.($|\.?\/)/
    end

    def resolve(path, &block)
      environment.resolve(path, :base_path => base_path, &block)
    end

    def base_path
      source_file.pathname.dirname
    end
  end
end
