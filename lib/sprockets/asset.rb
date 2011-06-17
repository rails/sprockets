module Sprockets
  class Asset
    attr_reader :environment
    attr_reader :logical_path, :pathname

    def content_type
      @content_type ||= environment.content_type_of(pathname)
    end

    def fresh?
      !stale?
    end

    def stale?
      !fresh?
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "pathname=#{pathname.to_s.inspect}, " +
        "mtime=#{mtime.inspect}, " +
        "digest=#{digest.inspect}" +
        ">"
    end

    def eql?(other)
      other.class == self.class &&
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      def environment_hexdigest
        @environment_hexdigest ||= environment.digest.hexdigest
      end

      def dependency_fresh?(dep = {})
        path, mtime, hexdigest = dep.values_at('path', 'mtime', 'hexdigest')

        stat = environment.stat(path)

        if stat.nil?
          return false
        end

        if mtime >= stat.mtime
          return true
        end

        digest = environment.file_digest(path)

        if hexdigest == digest.hexdigest
          return true
        end

        false
      end
  end
end
