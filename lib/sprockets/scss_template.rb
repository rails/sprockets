require 'sprockets/sass_template'

module Sprockets
  class ScssTemplate < SassTemplate
    self.default_mime_type = 'text/css'

    def syntax
      :scss
    end
  end
end
