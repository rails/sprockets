require 'sprockets/errors'
require 'sprockets/pathname'
require 'sprockets/source_file'
require 'tilt'
require 'yaml'

module Sprockets
  class Processor < Tilt::Template
    def prepare
      @source_file = SourceFile.new(file, data)

      @depended_pathnames = []
      @included_pathnames = []
      @required_pathnames = []
      @compat             = false
    end

    def evaluate(context, locals, &block)
      @context = context

      process_directives
      process_source
    end

    protected
      attr_reader :source_file
      attr_reader :depended_pathnames, :included_pathnames, :required_pathnames
      attr_reader :context

      def process_directives
        source_file.directives.each do |name, *args|
          send("process_#{name}_directive", *args)
        end
      end

      def process_source
        result = ""

        required_pathnames.each { |p| context.require(p) }
        result << source_file.header << "\n" unless source_file.header.empty?
        included_pathnames.each { |p| result << context.process(p) }
        result << source_file.body
        depended_pathnames.each { |p| context.depend(p) }

        # LEGACY
        if compat? && constants.any?
          result.gsub!(/<%=(.*?)%>/) { constants[$1.strip] }
        end

        result
      end

      def compat?
        @compat
      end

      # LEGACY
      def constants
        if compat?
          root_path = context.paths.detect { |path| source_file.pathname.to_s[path] }
          path = File.join(root_path, "constants.yml")
          File.exist?(path) ? YAML.load_file(path) : {}
        else
        {}
        end
      end

      def process_compat_directive
        @compat = true
      end

      def process_depend_directive(path)
        depended_pathnames << context.resolve(path)
      end

      def process_include_directive(path)
        included_pathnames << context.resolve(path)
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
            raise ContentTypeMismatch, "#{pathname} is " +
              "'#{pathname.format_extension}', not '#{source_file.pathname.format_extension}'"
          end
        end

        context.resolve(path) do |candidate|
          if source_file.content_type == candidate.content_type
            required_pathnames << candidate
            return
          end
        end

        raise FileNotFound, "couldn't find file '#{path}'"
      end

      def process_require_directory_directive(path = ".")
        if relative?(path)
          root = base_path.join(path).expand_path

          required_pathnames << root

          Dir["#{root}/*"].sort.each do |filename|
            pathname = Pathname.new(filename)
            if pathname.file? &&
                pathname.content_type == source_file.content_type
              required_pathnames << pathname
            end
          end
        else
          raise ArgumentError, "require_directory argument must be a relative path"
        end
      end

      def process_require_tree_directive(path = ".")
        if relative?(path)
          root = base_path.join(path).expand_path

          required_pathnames << root

          each_pathname_in_tree(path) do |pathname|
            required_pathnames << pathname
          end
        else
          raise ArgumentError, "require_tree argument must be a relative path"
        end
      end

      def process_provide_directive(path)
        # ignore
      end

    private
      def each_pathname_in_tree(path)
        Dir["#{base_path.join(path)}/**/*"].sort.each do |filename|
          pathname = Pathname.new(filename)

          if pathname.directory?
            yield pathname
          elsif pathname.file? &&
              pathname.content_type == source_file.content_type
            yield pathname
          end
        end
      end

      def relative?(path)
        path =~ /^\.($|\.?\/)/
      end

      def base_path
        source_file.pathname.dirname
      end
  end
end
