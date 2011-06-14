require 'multi_json'

module Sprockets
  class Dependency < Struct.new(:environment_hexdigest, :path, :mtime, :hexdigest)
    def self.from_path(environment, path)
      stat = environment.stat(path)
      raise ArgumentError unless stat
      hexdigest = environment.file_digest(path).hexdigest
      new(environment.digest.hexdigest, path.to_s, stat.mtime, hexdigest)
    end

    def self.from_json(json)
      json = MultiJson.decode(json) if json.is_a?(String)
      raise TypeError unless json['class'] == 'Dependency'
      new(json['env_hexdigest'], json['path'], Time.parse(json['mtime']), json['hexdigest'])
    end

    def fresh?(environment)
      if environment.digest.hexdigest != environment_hexdigest
        return false
      end

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

    def as_json
      { 'class'         => 'Dependency',
        'env_hexdigest' => environment_hexdigest,
        'path'          => path,
        'mtime'         => mtime,
        'hexdigest'     => hexdigest }
    end

    def to_json
      MultiJson.encode(as_json)
    end
  end
end
