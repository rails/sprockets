require 'json'

module Sprockets
  module Bower
    # Internal: Expand bower.json path to main.
    #
    # filename - String path to bower.json.
    # extname  - String extension name ".js", ".css".
    #
    # Returns String path to main file. Otherwise returns nil if filename is
    # not a bower.json
    def expand_bower_path(filename, extname)
      if File.basename(filename) == "bower.json"
        bower = JSON.parse(File.read(filename), create_additions: false)

        case bower['main']
        when String
          main = bower['main']
        when Array
          main = bower['main'].find { |fn| extname == File.extname(fn) }
        end

        File.expand_path("../#{main}", filename) if main
      end
    end
  end
end
