module Sprockets
  class Bundle
    def self.call(input)
      new.call(input)
    end

    def call(input)
      env = input[:environment]
      filename = input[:filename]

      processed_asset = env.send(:build_asset_hash, filename, false)

      cache = {}
      cache[filename] = processed_asset

      required_paths = expand_asset_deps(env, processed_asset[:required_paths], filename, cache)
      stubbed_paths  = expand_asset_deps(env, processed_asset[:stubbed_paths], filename, cache)
      required_paths.subtract(stubbed_paths)

      dependency_paths = Set.new
      required_asset_hashes = required_paths.map do |path|
        asset_hash = cache[path]
        dependency_paths.merge(asset_hash[:dependency_paths])
        asset_hash
      end

      data = required_asset_hashes.map { |h| h[:source] }.join

      { data: data,
        required_asset_hashes: required_asset_hashes,
        dependency_paths: dependency_paths.to_a }
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
          asset = cache[path] ||= env.send(:build_asset_hash, path, false)
          stack.concat(asset[:required_paths].reverse)
          seen.add(path)
        end
      end

      deps
    end
  end
end
