module Sprockets
  class SourceFile
    attr_reader :environment, :pathname

    def initialize(environment, pathname)
      @environment = environment
      @pathname = pathname
    end
    
    def each_source_line
      File.open(pathname.absolute_location) do |file|
        file.each do |line|
          yield SourceLine.new(self, line, file.lineno)
        end
      end
    end
    
    def find(location, kind = :file)
      pathname.parent_pathname.find(location, kind)
    end
    
    def ==(source_file)
      pathname == source_file.pathname
    end
    
    def mtime
      File.mtime(pathname.absolute_location)
    rescue Errno::ENOENT
      0
    end
  end
end
