module Sprockets
  module Paths
    # Returns `Environment` root.
    #
    # All relative paths are expanded with root as its base. To be
    # useful set this to your applications root directory. (`Rails.root`)
    attr_reader :root

    # Returns an `Array` of path `String`s.
    #
    # These paths will be used for asset logical path lookups.
    attr_reader :paths

    # Prepend a `path` to the `paths` list.
    #
    # Paths at the end of the `Array` have the least priority.
    def prepend_path(path)
      mutate_config(:paths) do |paths|
        path = File.expand_path(path, root).dup.freeze
        paths.unshift(path)
      end
    end

    # Append a `path` to the `paths` list.
    #
    # Paths at the beginning of the `Array` have a higher priority.
    def append_path(path)
      mutate_config(:paths) do |paths|
        path = File.expand_path(path, root).dup.freeze
        paths.push(path)
      end
    end

    # Clear all paths and start fresh.
    #
    # There is no mechanism for reordering paths, so its best to
    # completely wipe the paths list and reappend them in the order
    # you want.
    def clear_paths
      mutate_config(:paths) do |paths|
        paths.clear
      end
    end
  end
end
