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
      pathname = Pathname.new(filename)

      if pathname.basename.to_s == "bower.json"
        bower = JSON.parse(pathname.read, create_additions: false)

        case bower['main']
        when String
          main = bower['main']
        when Array
          main = bower['main'].find { |fn| extname == File.extname(fn) }
        end

        pathname.dirname.join(main).to_s if main
      end
    end
  end
end
