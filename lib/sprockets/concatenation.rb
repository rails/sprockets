require 'sprockets/asset_pathname'
require 'sprockets/errors'
require 'digest/md5'
require 'pathname'
require 'rack/utils'
require 'set'
require 'time'

module Sprockets
  class Concatenation
    attr_reader :environment, :pathname
    attr_reader :content_type, :format_extension
    attr_reader :paths
    attr_accessor :mtime

    def initialize(environment, pathname)
      @environment = environment
      @pathname    = Pathname.new(pathname)

      @content_type     = nil
      @format_extension = nil

      @paths  = Set.new
      @source = ""
      @mtime  = Time.at(0)
    end

    def digest
      Digest::MD5.hexdigest(to_s)
    end

    def length
      Rack::Utils.bytesize(to_s)
    end

    def to_s
      @source
    end

    def <<(str)
      @source << str.to_s
      self
    end

    def post_process!
      engines = environment.filters(content_type)
      @source = evaluate(pathname, :data => @source, :engines => engines)
      nil
    end

    def evaluate(pathname, *args)
      context = environment.context_class.new(self, pathname)
      context.evaluate(pathname, *args)
    end

    def depend_on(pathname)
      pathname = Pathname.new(pathname)

      if pathname.mtime > mtime
        self.mtime = pathname.mtime
      end

      paths << pathname.to_s

      pathname
    end

    def can_require?(pathname)
      pathname = Pathname.new(pathname)
      content_type = AssetPathname.new(pathname, environment).content_type
      pathname.file? && (self.content_type.nil? || self.content_type == content_type)
    end

    def require(pathname)
      pathname       = Pathname.new(pathname)
      asset_pathname = AssetPathname.new(pathname, environment)

      @content_type     ||= asset_pathname.content_type
      @format_extension ||= asset_pathname.format_extension

      if can_require?(pathname)
        unless paths.include?(pathname.to_s)
          depend_on(pathname)
          self << evaluate(pathname)
        end
      else
        raise ContentTypeMismatch, "#{pathname} is " +
          "'#{AssetPathname.new(pathname, environment).format_extension}', " +
          "not '#{format_extension}'"
      end

      pathname
    end
  end
end
