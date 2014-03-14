require 'sprockets/sass_template'

module Sprockets
  class ScssTemplate < SassTemplate
    def syntax
      :scss
    end
  end
end
