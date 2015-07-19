require 'sprockets/autoload'

module Sprockets
  class SassImporter < Autoload::Sass::Importers::Filesystem
    # NOTE: Hack to support sourcemap generation in Sass-3.3
    def public_url(*);'';end
  end
end
