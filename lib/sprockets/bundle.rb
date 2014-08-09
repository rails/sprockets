require 'set'

module Sprockets
  # Internal: Bundle processor takes a single file asset and prepends all the
  # `:required_paths` to the contents.
  #
  # Uses pipeline metadata:
  #
  #   :required_paths - Ordered Set of asset filenames to prepend
  #   :stubbed_paths  - Set of asset filenames to substract from the
  #                     required path set.
  #
  # Also see DirectiveProcessor.
  class Bundle
    def self.call(input)
      new.call(input)
    end

    def call(input)
      env      = input[:environment]
      filename = input[:filename]
      type     = input[:content_type]

      assets = Hash.new do |h, path|
        h[path] = env.find_asset(path, bundle: false, accept: type)
      end

      required_paths = expand_required_paths(env, assets, [filename])
      stubbed_paths  = expand_required_paths(env, assets, Array(assets[filename].metadata[:stubbed_paths]))
      required_paths.subtract(stubbed_paths)

      reduce_assets(required_paths.map { |path| assets[path] })
    end

    private
      def reduce_assets(assets)
        assets.reduce({}) do |h, asset|
          h[:data] ||= "".force_encoding(Encoding::UTF_8)
          h[:data] << map_asset_source(asset)

          h[:dependency_paths] ||= Set.new
          h[:dependency_paths].merge(asset.metadata[:dependency_paths])

          # Deprecated: For Asset#to_a
          h[:required_asset_hashes] ||= []
          h[:required_asset_hashes] << asset.to_hash

          h
        end
      end

      def map_asset_source(asset)
        asset.to_s
      end

      def expand_required_paths(env, assets, paths)
        deps, seen = Set.new, Set.new
        stack = paths.reverse

        while path = stack.pop
          if seen.include?(path)
            deps.add(path)
          else
            unless asset = assets[path]
              raise FileNotFound, "could not find #{path}"
            end
            stack.push(path)
            stack.concat(Array(asset.metadata[:required_paths]).reverse)
            seen.add(path)
          end
        end

        deps
      end

      def join_assets(ary)
        ary.join
      end
  end

  class StylesheetBundle < Bundle
  end

  class JavascriptBundle < Bundle
    # Internal: Check if data is missing a trailing semicolon.
    #
    # data - String
    #
    # Returns true or false.
    def self.missing_semicolon?(data)
      i = data.size - 1
      while i >= 0
        c = data[i]
        i -= 1
        if c == "\n" || c == " " || c == "\t"
          next
        elsif c != ";"
          return true
        else
          return false
        end
      end
      false
    end

    def map_asset_source(asset)
      data = asset.to_s
      if self.class.missing_semicolon?(data)
        data + ";\n"
      else
        data
      end
    end
  end
end
