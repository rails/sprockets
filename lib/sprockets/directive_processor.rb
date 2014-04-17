require 'pathname'
require 'set'
require 'shellwords'
require 'yaml'

module Sprockets
  # The `DirectiveProcessor` is responsible for parsing and evaluating
  # directive comments in a source file.
  #
  # A directive comment starts with a comment prefix, followed by an "=",
  # then the directive name, then any arguments.
  #
  #     // JavaScript
  #     //= require "foo"
  #
  #     # CoffeeScript
  #     #= require "bar"
  #
  #     /* CSS
  #      *= require "baz"
  #      */
  #
  # This makes it possible to disable or modify the processor to do whatever
  # you'd like. You could add your own custom directives or invent your own
  # directive syntax.
  #
  # `Environment#processors` includes `DirectiveProcessor` by default.
  #
  # To remove the processor entirely:
  #
  #     env.unregister_processor('text/css', Sprockets::DirectiveProcessor)
  #     env.unregister_processor('application/javascript', Sprockets::DirectiveProcessor)
  #
  # Then inject your own preprocessor:
  #
  #     env.register_processor('text/css', MyProcessor)
  #
  class DirectiveProcessor
    # Directives will only be picked up if they are in the header
    # of the source file. C style (/* */), JavaScript (//), and
    # Ruby (#) comments are supported.
    #
    # Directives in comments after the first non-whitespace line
    # of code will not be processed.
    #
    HEADER_PATTERN = /
      \A (
        (?m:\s*) (
          (\/\* (?m:.*?) \*\/) |
          (\#\#\# (?m:.*?) \#\#\#) |
          (\/\/ .* \n?)+ |
          (\# .* \n?)+
        )
      )+
    /x

    # Directives are denoted by a `=` followed by the name, then
    # argument list.
    #
    # A few different styles are allowed:
    #
    #     // =require foo
    #     //= require foo
    #     //= require "foo"
    #
    DIRECTIVE_PATTERN = /
      ^ \W* = \s* (\w+.*?) (\*\/)? $
    /x

    def self.call(input)
      new.call(input)
    end

    def call(input)
      @environment = input[:environment]
      @filename = input[:filename]
      @base_path = Pathname.new(@filename).dirname
      @content_type = input[:content_type]

      data = input[:data]
      @header = data[HEADER_PATTERN, 0] || ""
      @body   = $' || data
      # Ensure body ends in a new line
      @body  += "\n" if @body != "" && @body !~ /\n\Z/m

      @result = ""
      @result.force_encoding(@body.encoding)

      @has_written_body = false

      @required_paths   = []
      @stubbed_assets   = Set.new
      @dependency_paths = Set.new

      process_directives
      process_source

      {
        data: @result,
        required_paths: @required_paths,
        stubbed_assets: @stubbed_assets,
        dependency_paths: @dependency_paths
      }
    end

    # Returns the header String with any directives stripped.
    def processed_header
      lineno = 0
      @processed_header ||= @header.lines.map { |line|
        lineno += 1
        # Replace directive line with a clean break
        directives.assoc(lineno) ? "\n" : line
      }.join.chomp
    end

    # Returns an Array of directive structures. Each structure
    # is an Array with the line number as the first element, the
    # directive name as the second element, followed by any
    # arguments.
    #
    #     [[1, "require", "foo"], [2, "require", "bar"]]
    #
    def directives
      @directives ||= @header.lines.each_with_index.map { |line, index|
        if directive = line[DIRECTIVE_PATTERN, 1]
          name, *args = Shellwords.shellwords(directive)
          if respond_to?("process_#{name}_directive", true)
            [index + 1, name, *args]
          end
        end
      }.compact
    end

    protected
      # Gathers comment directives in the source and processes them.
      # Any directive method matching `process_*_directive` will
      # automatically be available. This makes it easy to extend the
      # processor.
      #
      # To implement a custom directive called `require_glob`, subclass
      # `Sprockets::DirectiveProcessor`, then add a method called
      # `process_require_glob_directive`.
      #
      #     class DirectiveProcessor < Sprockets::DirectiveProcessor
      #       def process_require_glob_directive
      #         Dir["#{pathname.dirname}/#{glob}"].sort.each do |filename|
      #           require(filename)
      #         end
      #       end
      #     end
      #
      # Replace the current processor on the environment with your own:
      #
      #     env.unregister_processor('text/css', Sprockets::DirectiveProcessor)
      #     env.register_processor('text/css', DirectiveProcessor)
      #
      def process_directives
        directives.each do |line_number, name, *args|
          begin
            send("process_#{name}_directive", *args)
          rescue Exception => e
            e.set_backtrace(["#{@filename}:#{line_number}"] + e.backtrace)
            raise e
          end
        end
      end

      def process_source
        unless @has_written_body || processed_header.empty?
          @result << processed_header << "\n"
        end

        unless @has_written_body
          @result << @body
        end
      end

      # The `require` directive functions similar to Ruby's own `require`.
      # It provides a way to declare a dependency on a file in your path
      # and ensures its only loaded once before the source file.
      #
      # `require` works with files in the environment path:
      #
      #     //= require "foo.js"
      #
      # Extensions are optional. If your source file is ".js", it
      # assumes you are requiring another ".js".
      #
      #     //= require "foo"
      #
      # Relative paths work too. Use a leading `./` to denote a relative
      # path:
      #
      #     //= require "./bar"
      #
      def process_require_directive(path)
        filename = resolve(path, content_type: @content_type)
        @required_paths << filename
      end

      # `require_self` causes the body of the current file to be inserted
      # before any subsequent `require` directives. Useful in CSS files, where
      # it's common for the index file to contain global styles that need to
      # be defined before other dependencies are loaded.
      #
      #     /*= require "reset"
      #      *= require_self
      #      *= require_tree .
      #      */
      #
      def process_require_self_directive
        if @has_written_body
          raise ArgumentError, "require_self can only be called once per source file"
        end

        @required_paths << @filename
        process_source
        @has_written_body = true
      end

      # `require_directory` requires all the files inside a single
      # directory. It's similar to `path/*` since it does not follow
      # nested directories.
      #
      #     //= require_directory "./javascripts"
      #
      def process_require_directory_directive(path = ".")
        if relative?(path)
          root = @base_path.join(path).expand_path

          unless (stats = @environment.stat(root)) && stats.directory?
            raise ArgumentError, "require_directory argument must be a directory"
          end

          @dependency_paths << root.to_s

          @environment.stat_directory(root).each do |subpath, stat|
            if subpath == @filename
              next
            elsif stat.file? && @environment.content_type_of(subpath) == @content_type
              @required_paths << subpath
            end
          end
        else
          # The path must be relative and start with a `./`.
          raise ArgumentError, "require_directory argument must be a relative path"
        end
      end

      # `require_tree` requires all the nested files in a directory.
      # Its glob equivalent is `path/**/*`.
      #
      #     //= require_tree "./public"
      #
      def process_require_tree_directive(path = ".")
        if relative?(path)
          root = @base_path.join(path).expand_path

          unless (stats = @environment.stat(root)) && stats.directory?
            raise ArgumentError, "require_tree argument must be a directory"
          end

          @dependency_paths << root.to_s

          required_paths = []
          @environment.stat_tree(root).each do |subpath, stat|
            if subpath == @filename
              next
            elsif stat.directory?
              @dependency_paths << subpath
            elsif stat.file? && @environment.content_type_of(subpath) == @content_type
              required_paths << subpath
            end
          end
          required_paths.sort_by(&:to_s).each do |filename|
            @required_paths << filename
          end
        else
          # The path must be relative and start with a `./`.
          raise ArgumentError, "require_tree argument must be a relative path"
        end
      end

      # Allows you to state a dependency on a file without
      # including it.
      #
      # This is used for caching purposes. Any changes made to
      # the dependency file will invalidate the cache of the
      # source file.
      #
      # This is useful if you are using ERB and File.read to pull
      # in contents from another file.
      #
      #     //= depend_on "foo.png"
      #
      def process_depend_on_directive(path)
        @dependency_paths << resolve(path)
      end

      # Allows you to state a dependency on an asset without including
      # it.
      #
      # This is used for caching purposes. Any changes that would
      # invalid the asset dependency will invalidate the cache our the
      # source file.
      #
      # Unlike `depend_on`, the path must be a requirable asset.
      #
      #     //= depend_on_asset "bar.js"
      #
      def process_depend_on_asset_directive(path)
        if asset = @environment.find_asset(resolve(path))
          @dependency_paths.merge(asset.send(:dependency_paths))
        end
      end

      # Allows dependency to be excluded from the asset bundle.
      #
      # The `path` must be a valid asset and may or may not already
      # be part of the bundle. Once stubbed, it is blacklisted and
      # can't be brought back by any other `require`.
      #
      #     //= stub "jquery"
      #
      def process_stub_directive(path)
        @stubbed_assets << resolve(path, content_type: @content_type)
      end

    private
      def relative?(path)
        path =~ /^\.($|\.?\/)/
      end

      def resolve(path, options = {})
        @environment.resolve(path, options.merge(base_path: @base_path))
      end
  end
end
