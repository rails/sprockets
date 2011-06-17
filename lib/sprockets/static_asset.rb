require 'sprockets/dependency'
require 'fileutils'
require 'time'
require 'zlib'

module Sprockets
  class StaticAsset
    attr_reader :environment
    attr_reader :logical_path, :pathname

    def self.from_hash(environment, hash)
      asset = allocate
      asset.init_with(environment, hash)
      asset
    end

    def initialize(environment, logical_path, pathname, digest = nil)
      @environment  = environment
      @logical_path = logical_path.to_s
      @pathname     = Pathname.new(pathname)
      @digest       = digest

      load!
    end

    def self.serialized_attributes
      %w( environment_hexdigest
          logical_path pathname
          content_type mtime length digest )
    end

    def init_with(environment, coder)
      @environment = environment

      self.class.serialized_attributes.each do |attr|
        instance_variable_set("@#{attr}", coder[attr].to_s) if coder[attr]
      end

      @pathname = Pathname.new(@pathname) if @pathname.is_a?(String)
      @mtime    = Time.parse(@mtime)      if @mtime.is_a?(String)
      @length   = Integer(@length)        if @length.is_a?(String)
    end

    def encode_with(coder)
      coder['class'] = 'StaticAsset'

      self.class.serialized_attributes.each do |attr|
        coder[attr] = send(attr).to_s
      end
    end

    def content_type
      @content_type ||= environment.content_type_of(pathname)
    end

    def mtime
      @mtime ||= environment.stat(pathname).mtime
    end

    def length
      @length ||= environment.stat(pathname).size
    end

    def digest
      @digest ||= environment.file_digest(pathname).hexdigest
    end

    def dependencies
      []
    end

    def dependencies?
      false
    end

    def to_a
      [self]
    end

    def body
      to_s
    end

    def fresh?
      if environment.digest.hexdigest != environment_hexdigest
        return false
      end

      Dependency.new(pathname, mtime, digest).fresh?(environment)
    end

    def stale?
      !fresh?
    end

    def each
      yield to_s
    end

    def to_path
      pathname.to_s
    end

    def to_s
      pathname.open('rb') { |f| f.read }
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "pathname=#{pathname.to_s.inspect}, " +
        "mtime=#{mtime.inspect}, " +
        "digest=#{digest.inspect}" +
        ">"
    end

    def write_to(filename, options = {})
      options[:compress] ||= File.extname(filename) == '.gz'

      if options[:compress]
        pathname.open('rb') do |rd|
          File.open("#{filename}+", 'wb') do |wr|
            gz = Zlib::GzipWriter.new(wr, Zlib::BEST_COMPRESSION)
            buf = ""
            while rd.read(16384, buf)
              gz.write(buf)
            end
            gz.close
          end
        end
      else
        FileUtils.cp(pathname, "#{filename}+")
      end

      FileUtils.mv("#{filename}+", filename)
      File.utime(mtime, mtime, filename)

      nil
    ensure
      FileUtils.rm("#{filename}+") if File.exist?("#{filename}+")
    end

    def eql?(other)
      other.class == self.class &&
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      def load!
        content_type
        mtime
        length
        digest
        environment_hexdigest
      end

      def environment_hexdigest
        @environment_hexdigest ||= environment.digest.hexdigest
      end
  end
end
