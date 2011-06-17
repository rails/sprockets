module Sprockets
  class Dependency
    attr_reader :path, :mtime, :hexdigest

    def self.from_path(environment, path)
      stat = environment.stat(path)
      raise ArgumentError unless stat
      new(path.to_s, stat.mtime, environment.file_digest(path))
    end

    def self.from_hash(hash)
      raise TypeError unless hash['class'] == 'Dependency'
      new(hash['path'], hash['mtime'], hash['hexdigest'])
    end

    def initialize(path, mtime, hexdigest)
      self.path      = path
      self.mtime     = mtime
      self.hexdigest = hexdigest
    end

    def init_with(coder)
      self.path      = coder['path']
      self.mtime     = coder['mtime']
      self.hexdigest = coder['hexdigest']
    end

    def encode_with(coder)
      coder['class']     = 'Dependency'
      coder['path']      = path
      coder['mtime']     = mtime
      coder['hexdigest'] = hexdigest
    end

    def path=(path)
      @path = path.to_s
    end

    def mtime=(time)
      if time.is_a?(String)
        @mtime = Time.parse(time)
      else
        @mtime = time
      end
    end

    def hexdigest=(digest)
      if digest.respond_to?(:hexdigest)
        @hexdigest = digest.hexdigest
      else
        @hexdigest = digest
      end
    end

    def fresh?(environment)
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

    def stale?(environment)
      !fresh?(environment)
    end
  end
end
