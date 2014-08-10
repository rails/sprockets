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

    DEFAULT_REDUCERS = {
      data: proc { |data, asset|
        data ||= "".force_encoding(Encoding::UTF_8)
        data << asset.to_s
      },

      dependency_paths: proc { |paths, asset|
        paths ||= Set.new
        paths.merge(asset.metadata[:dependency_paths])
      },

      # Deprecated: For Asset#to_a
      required_asset_hashes: proc { |hashes, asset|
        hashes ||= []
        hashes << asset.to_hash
      }
    }.freeze

    def initialize(options = {})
      options[:reducers] ||= {}
      @reducers = DEFAULT_REDUCERS.merge(options[:reducers])
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

      required_paths.reduce({}) do |h, path|
        asset = assets[path]
        @reducers.each { |k, fn| h[k] = fn.call(h[k], asset) }
        h
      end
    end
  end

  class StylesheetBundle < Bundle
  end

  class JavascriptBundle < Bundle

    def initialize(options = {})
      options[:reducers] ||= {}
      options[:reducers][:data] = proc { |data, asset|
        data ||= "".force_encoding(Encoding::UTF_8)
        contents = asset.to_s
        if JavascriptBundle.missing_semicolon?(contents)
          data << contents << ";\n"
        else
          data << contents
        end
      }
      super(options)
    end

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
  end
end
