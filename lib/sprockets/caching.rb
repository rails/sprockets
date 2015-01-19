require 'sprockets/digest_utils'
require 'sprockets/path_digest_utils'
require 'sprockets/uri_utils'

module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on the
  # `Environment` and `CachedEnvironment` classes.
  module Caching
    include DigestUtils, PathDigestUtils, URIUtils

    def cache_dependencies
      config[:cache_dependencies]
    end

    def add_cache_dependency(uri)
      self.config = hash_reassoc(config, :cache_dependencies) do |set|
        set + Set.new([uri])
      end
    end

    def resolve_cache_dependencies(uris)
      digest(uris.map { |uri| resolve_cache_dependency(uri) })
    end

    def cache_resolvers
      config[:cache_resolvers]
    end

    def register_cache_resolver(scheme, &block)
      self.config = hash_reassoc(config, :cache_resolvers) do |hash|
        hash.merge(scheme => block)
      end
    end

    def resolve_cache_dependency(str)
      scheme = str =~ /:/ ? URI.split(str)[0] : str
      if resolver = cache_resolvers[scheme]
        resolver.call(self, str)
      else
        raise TypeError, "unknown cache scheme: #{scheme}"
      end
    end
  end
end
