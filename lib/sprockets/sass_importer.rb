module Sprockets
  # This custom importer adds sprockets dependency tracking on to Sass
  # `@import` statements. This makes the Sprockets and Sass caching
  # systems work together.
  class SassImporter
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def evaluate(pathname, options)
      # Mark pathname as a dependency for cache tracking
      context.depend_on_asset(pathname)

      options = options.merge(:filename => pathname.to_s,  :syntax => :scss)
      syntax  = pathname.extname[/\w+$/].to_sym

      case syntax
      when :sass, :scss
        # `foo.sass` and `foo.scss` can be read directly by sass.
        ::Sass::Engine.new(pathname.read, options.merge(:syntax => syntax))
      else
        # If the file something else like a `foo.css.erb`, have
        # sprockets process it first before handing it off to sass.
        ::Sass::Engine.new(context.evaluate(pathname), options)
      end
    end

    # Find relative path to asset in load path and return its Pathname.
    def resolve_relative(path, basepath)
      dirname, basename = File.split(path)

      # Ensure resolve is always called with a leading "./" to force a
      # relative lookup.
      if dirname == '.'
        resolve("./_#{basename}", :base_path => basepath) ||
          resolve("./#{basename}", :base_path => basepath)
      else
        resolve("./#{dirname}/_#{basename}", :base_path => basepath) ||
          resolve("./#{dirname}/#{basename}", :base_path => basepath)
      end
    end

    # Find full path to asset in load path and return its Pathname.
    def resolve_loadpath(path)
      return if path.to_s =~ /^\.\.?\//
      dirname, basename = File.split(path)

      # Strip any leading "./" to force a load path lookup.
      if dirname == '.'
        resolve("_#{basename}") || resolve("#{basename}")
      else
        resolve("#{dirname}/_#{basename}") || resolve("#{dirname}/#{basename}")
      end
    end

    def resolve(path, options = {})
      context.resolve(path, {:content_type => :self}.merge(options))
    rescue Sprockets::FileNotFound
      nil
    end

    # Find asset relative to the current file and return a `Sass::Engine`.
    def find_relative(path, base, options)
      if pathname = resolve_relative(path, :base_path => File.dirname(base))
        evaluate(pathname, options)
      end
    end

    # Find asset in Sprockets load path and return a `Sass::Engine`.
    def find(path, options)
      if pathname = resolve_loadpath(path)
        evaluate(pathname, options)
      end
    end

    # Return mtime for path.
    #
    # (This method doesn't seem to ever be called)
    def mtime(path, options)
      if pathname = resolve_loadpath(path)
        pathname.mtime
      end
    end

    # Return cache key for Sass's cache system.
    def key(name, options)
      ["Sprockets:" + File.dirname(File.expand_path(name)), File.basename(name)]
    end

    # Pretty inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "logical_path=#{context.logical_path.to_s.inspect}" +
        ">"
    end

    def to_s
      inspect
    end
  end
end
