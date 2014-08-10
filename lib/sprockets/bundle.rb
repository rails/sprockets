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
        unless asset = env.find_asset(path, bundle: false, accept: type)
          raise FileNotFound, "could not find #{path}"
        end
        h[path] = asset
      end

      find_required_paths = proc { |path| assets[path].metadata[:required_paths] }
      required_paths = Utils.dfs(filename, &find_required_paths)
      stubbed_paths  = Utils.dfs(assets[filename].metadata[:stubbed_paths], &find_required_paths)
      required_paths.subtract(stubbed_paths)

      dependency_paths = required_paths.inject(Set.new) do |set, path|
        set.merge(assets[path].metadata[:dependency_paths])
      end

      data = join_assets(required_paths.map { |path| assets[path].to_s })

      # Deprecated: For Asset#to_a
      required_asset_hashes = required_paths.map { |path| assets[path].to_hash }

      { data: data,
        required_asset_hashes: required_asset_hashes,
        dependency_paths: dependency_paths }
    end

    private
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

    def join_assets(ary)
      ary.map do |data|
        if self.class.missing_semicolon?(data)
          data + ";\n"
        else
          data
        end
      end.join
    end
  end
end
