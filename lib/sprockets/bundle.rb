require 'set'

module Sprockets
  class Bundle
    def self.call(input)
      new.call(input)
    end

    def call(input)
      env = input[:environment]
      filename = input[:filename]

      unless processed_asset = env.find_asset(filename, bundle: false)
        raise FileNotFound, "could not find #{filename}"
      end

      cache = {}
      cache[filename] = processed_asset

      required_paths = expand_asset_deps(env, Array(processed_asset.metadata[:required_paths]) + [filename], filename, cache)
      stubbed_paths  = expand_asset_deps(env, Array(processed_asset.metadata[:stubbed_paths]), filename, cache)
      required_paths.subtract(stubbed_paths)

      dependency_paths = Set.new
      required_asset_hashes = required_paths.map do |path|
        asset = cache[path]
        dependency_paths.merge(asset.metadata[:dependency_paths])
        asset.to_hash
      end

      data = required_asset_hashes.map { |h| h[:source] }.join

      { data: data,
        required_asset_hashes: required_asset_hashes,
        dependency_paths: dependency_paths }
    end

    def expand_asset_deps(env, paths, path, cache)
      stack = []
      stack.concat(paths.reverse)

      deps = Set.new

      seen = Set.new
      seen.add(path)

      while path = stack.pop
        if seen.include?(path)
          deps.add(path)
        else
          unless asset = cache[path] ||= env.find_asset(path, bundle: false)
            raise FileNotFound, "could not find #{path}"
          end

          stack.push(path)
          stack.concat(Array(asset.metadata[:required_paths]).reverse)
          seen.add(path)
        end
      end

      deps
    end
  end
end
