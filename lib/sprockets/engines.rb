require 'sprockets/asset_pathname'
require 'sprockets/directive_processor'
require 'tilt'

module Sprockets
  class Engines
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    attr_reader :pre_processors

    def initialize(environment)
      @environment = environment
      @mappings = {}

      @pre_processors = [DirectiveProcessor]

      if @environment
        extensions.each do |ext|
          @environment.extensions << ext
        end
      end
    end

    def initialize_copy(other)
      @mappings = @mappings.dup
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
      @mappings[ext] || Tilt[ext]
    end
    alias_method :[], :lookup

    def extensions
      exts = (Tilt.mappings.keys + @mappings.keys)
      exts = exts.reject { |ext| ext == "" }.uniq.compact
      exts.map { |ext| ".#{ext}" }
    end

    def concatenatable?(pathname)
      CONCATENATABLE_EXTENSIONS.include?(AssetPathname.new(pathname, @environment).format_extension)
    end
  end
end
