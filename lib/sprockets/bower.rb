require 'json'

module Sprockets
  module Bower
    POSSIBLE_BOWER_JSONS = ['bower.json']

    # Internal: Override resolve_alternates to install bower.json behavior.
    #
    # base_path    - String environment path
    # logical_path - String path relative to base
    #
    # Returns an Array of String filenames.
    def resolve_alternates(base_path, logical_path)
      paths = super

      # bower.json can only be nested one level deep
      if !logical_path.index('/')
        dirname = File.expand_path(logical_path, base_path)
        stat    = self.stat(dirname)

        if stat && stat.directory?
          filenames = POSSIBLE_BOWER_JSONS.map { |basename| File.join(dirname, basename) }
          filename  = filenames.detect { |fn| (stat = self.stat(fn)) && stat.file? }

          if filename
            paths += read_bower_main(filename)
          end
        end
      end

      paths
    end

    # Internal: Read bower.json's main directive.
    #
    # filename - String path to bower.json.
    #
    # Returns an Array of String filenames.
    def read_bower_main(filename)
      bower = JSON.parse(File.read(filename), create_additions: false)

      case bower['main']
      when String
        [File.expand_path("../#{bower['main']}", filename)]
      when Array
        bower['main'].map do |name|
          File.expand_path("../#{name}", filename)
        end
      else
        []
      end
    end
  end
end
