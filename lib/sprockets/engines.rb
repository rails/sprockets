require 'tilt'

module Sprockets
  class Engines
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    def initialize(environment = nil)
      @environment = environment
      @mappings = Tilt.mappings.dup

      if @environment
        extensions.each do |ext|
          @environment.extensions << ext
        end
      end
    end

    def initialize_copy(other)
      @mappings = @mappings.dup
      @trail = nil
    end

    def register(ext, klass)
      ext = ext.to_s.sub(/^\./, '').downcase

      if @environment
        @environment.extensions << ext
      end

      @mappings[ext] = klass
    end
    alias_method :[]=, :register

    def lookup(ext)
      ext = ext.to_s.sub(/^\./, '').downcase
      @mappings[ext]
    end
    alias_method :[], :lookup

    def extensions
      @mappings.keys.map { |ext| ".#{ext}" }
    end

    def concatenatable?(pathname)
      CONCATENATABLE_EXTENSIONS.include?(EnginePathname.new(pathname, self).format_extension)
    end
  end
end
