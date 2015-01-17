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

    def resolve_cache_dependency(str)
      case scheme = URI.split(str)[0]
      when "env-version"
        [VERSION, self.version]
      when "env-paths"
        self.paths
      when "file-digest"
        file_digest(parse_file_digest_uri(str))
      else
        raise TypeError, "unknown cache scheme: #{scheme}"
      end
    end
  end
end
