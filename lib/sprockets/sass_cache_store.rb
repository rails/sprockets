require 'sass'

module Sprockets
  class SassCacheStore < ::Sass::CacheStores::Base
    VERSION = '1'

    def initialize(cache)
      @cache = cache
    end

    def _store(key, version, sha, contents)
      @cache["#{VERSION}/#{version}/#{key}/#{sha}"] = contents
    end

    def _retrieve(key, version, sha)
      @cache["#{VERSION}/#{version}/#{key}/#{sha}"]
    end

    def path_to(key)
      key
    end
  end
end
