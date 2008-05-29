module Sprockets
  class Environment
    attr_reader :root, :load_path
    
    def initialize(root, load_path = [])
      @root = pathname_from(File.expand_path(root))
      @load_path = [@root]
      
      load_path.each do |location|
        register_load_location(location)
      end
    end
    
    def absolute_location_from(location)
      location = location.to_s
      location = File.join(root.absolute_location, location) unless location[/^\//]
      File.expand_path(location)
    end
    
    def pathname_from(location)
      Pathname.new(self, absolute_location_from(location))
    end

    def register_load_location(location)
      pathname = pathname_from(location)
      load_path.delete(pathname)
      load_path.unshift(pathname)
      location
    end
    
    def find(location)
      load_path.map { |pathname| pathname.find(location) }.compact.first
    end
  end
end
