module Sprockets
  class SassImporter
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def evaluate(pathname, options)
      context.depend_on_asset(pathname)

      options = options.merge(:filename => pathname.to_s,  :syntax => :scss)
      syntax  = pathname.extname[/\w+$/].to_sym

      case syntax
      when :sass, :scss
        ::Sass::Engine.new(pathname.read, options.merge(:syntax => syntax))
      else
        ::Sass::Engine.new(context.evaluate(pathname), options)
      end
    end

    def resolve_relative(path, basepath)
      dirname, basename = File.split(path)

      if dirname == '.'
        resolve("./_#{basename}", :base_path => basepath) ||
          resolve("./#{basename}", :base_path => basepath)
      else
        resolve("./#{dirname}/_#{basename}", :base_path => basepath) ||
          resolve("./#{dirname}/#{basename}", :base_path => basepath)
      end
    end

    def resolve_loadpath(path)
      return if path.to_s =~ /^\.\.?\//
      dirname, basename = File.split(path)

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

    def find_relative(path, base, options)
      if pathname = resolve_relative(path, :base_path => File.dirname(base))
        evaluate(pathname, options)
      end
    end

    def find(path, options)
      if pathname = resolve_loadpath(path)
        evaluate(pathname, options)
      end
    end

    def mtime(path, options)
      if pathname = resolve_loadpath(path)
        pathname.mtime
      end
    end

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
