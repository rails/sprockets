require 'sprockets/errors'
require 'sprockets/pathname'
require 'sprockets/processor'
require 'digest/md5'
require 'rack/utils'
require 'set'
require 'time'

module Sprockets
  class Concatenation
    attr_reader :environment
    attr_reader :content_type, :format_extension
    attr_reader :paths, :source
    attr_accessor :length, :mtime

    def initialize(environment)
      @environment  = environment

      @content_type     = nil
      @format_extension = nil

      @paths  = Set.new
      @source = []
      @length = 0
      @mtime  = Time.at(0)
      @digest = Digest::MD5.new
    end

    def digest
      @digest.is_a?(String) ? @digest : @digest.hexdigest
    end

    def to_s
      source.join
    end

    def <<(str)
      str = str.to_s
      @length += Rack::Utils.bytesize(str)
      @digest << str
      @source << str
      str
    end

    def source=(str)
      str = str.to_s
      @length = Rack::Utils.bytesize(str)
      @digest.update(str)
      @source = [str]
      str
    end

    def compress!
      case content_type
      when 'application/javascript'
        if environment.js_compressor
          self.source = environment.js_compressor.compress(to_s)
        end
      when 'text/css'
        if environment.css_compressor
          self.source = environment.css_compressor.compress(to_s)
        end
      end
      nil
    end

    def depend(pathname)
      if pathname.mtime > mtime
        self.mtime = pathname.mtime
      end

      paths << pathname.to_s

      pathname
    end

    def requirable?(pathname)
      content_type.nil? || content_type == pathname.content_type
    end

    def require(pathname)
      @content_type     ||= pathname.content_type
      @format_extension ||= pathname.format_extension

      if requirable?(pathname)
        unless paths.include?(pathname.to_s)
          depend pathname
          self << process(pathname)
        end
      else
        raise ContentTypeMismatch, "#{pathname} is " +
          "'#{pathname.format_extension}', not '#{format_extension}'"
      end

      pathname
    end

    def process(pathname)
      engines  = pathname.engines + [Processor]
      scope    = environment.context.new(self, pathname)
      locals   = {}

      engines.reverse.inject(pathname.read) do |result, engine|
        template = engine.new(pathname.to_s) { result }
        template.render(scope, locals)
      end
    end
  end
end
