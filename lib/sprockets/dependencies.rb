require 'sprockets/digest_utils'
require 'sprockets/path_digest_utils'
require 'sprockets/uri_utils'

module Sprockets
  # `Dependencies` is an internal mixin whose public methods are exposed on the
  # `Environment` and `CachedEnvironment` classes.
  module Dependencies
    include DigestUtils, PathDigestUtils, URIUtils

    # Public: Mapping dependency schemes to resolver functions.
    #
    # key   - String scheme
    # value - Proc.call(Environment, String)
    #
    # Returns Hash.
    def dependency_resolvers
      config[:dependency_resolvers]
    end

    # Public: Default set of dependency URIs for assets.
    #
    # Returns Set of String URIs.
    def dependencies
      config[:dependencies]
    end

    # Public: Register new dependency URI resolver.
    #
    # scheme - String scheme
    # block  -
    #   environment - Environment
    #   uri - String dependency URI
    #
    # Returns nothing.
    def register_dependency_resolver(scheme, &block)
      self.config = hash_reassoc(config, :dependency_resolvers) do |hash|
        hash.merge(scheme => block)
      end
    end

    # Public: Add environmental dependency inheirted by all assets.
    #
    # uri - String dependency URI
    #
    # Returns nothing.
    def add_dependency(uri)
      self.config = hash_reassoc(config, :dependencies) do |set|
        set + Set.new([uri])
      end
    end
    alias_method :depend_on, :add_dependency

    # Internal: Resolve set of dependency URIs.
    #
    # Returns Array of resolved Objects.
    def resolve_dependencies(uris)
      uris.map { |uri| resolve_dependency(uri) }
    end

    # Internal: Resolve dependency URIs.
    #
    # Returns resolved Object.
    def resolve_dependency(str)
      scheme = str[/([^:]+)/, 1]
      if resolver = config[:dependency_resolvers][scheme]
        resolver.call(self, str)
      else
        nil
      end
    end
  end
end
