require 'tilt'

module Sprockets
  class Engines
    DEFAULT_ENGINE_EXTENSIONS = %w( .coffee .erb .less .sass .scss .str )
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    def initialize
      @mappings = Tilt.mappings.dup
    end

    def register(ext, klass)
      ext = ext.to_s.sub(/^\./, '').downcase
      @mappings[ext] = klass
    end

    def lookup_engine(ext)
      ext = ext.to_s.sub(/^\./, '').downcase
      @mappings[ext]
    end

    def concatenatable?(pathname)
      CONCATENATABLE_EXTENSIONS.include?(EnginePathname.new(pathname, self).format_extension)
    end
  end
end
