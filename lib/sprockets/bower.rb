require 'json'

module Sprockets
  module Bower
    # Internal: Expand bower.json path to main.
    #
    # filename - String path to bower.json.
    #
    # Returns String path to main file. Otherwise returns nil if filename is
    # not a bower.json
    def expand_bower_path(filename)
      bower = JSON.parse(File.read(filename), create_additions: false)

      case bower['main']
      when String
        yield File.expand_path("../#{bower['main']}", filename)
      when Array
        bower['main'].each do |name|
          yield File.expand_path("../#{name}", filename)
        end
      end
    end
  end
end
