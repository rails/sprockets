require 'fileutils'

module Sprockets
  # Internal: File and path related utilities. Mixed into Environment.
  #
  # Probably would be called FileUtils, but that causes namespace annoyances
  # when code actually wants to reference ::FileUtils.
  module PathUtils
    extend self

    # Public: Like `File.stat`.
    #
    # path - String file or directory path
    #
    # Returns nil if the file does not exist.
    def stat(path)
      File.stat(path.to_s) if File.exist?(path)
    end

    # Public: Like `File.file?`.
    #
    # path - String file path.
    #
    # Returns true path exists and is a file.
    def file?(path)
      if stat = self.stat(path)
        stat.file?
      else
        false
      end
    end

    # Public: Like `File.directory?`.
    #
    # path - String file path.
    #
    # Returns true path exists and is a directory.
    def directory?(path)
      if stat = self.stat(path)
        stat.directory?
      else
        false
      end
    end

    # Public: A version of `Dir.entries` that filters out `.` files and `~`
    # swap files.
    #
    # path - String directory path
    #
    # Returns an empty `Array` if the directory does not exist.
    def entries(path)
      if File.directory?(path)
        entries = Dir.entries(path, encoding: Encoding.default_internal)
        entries.reject! do |entry|
          entry =~ /^\.|~$|^\#.*\#$/
        end
        entries.sort!
        entries
      else
        []
      end
    end

    # Public: Check if path is absolute or relative.
    #
    # path - String path.
    #
    # Returns true if path is absolute, otherwise false.
    if File::ALT_SEPARATOR
      require 'pathname'

      # On Windows, ALT_SEPARATOR is \
      # Delegate to Pathname since the logic gets complex.
      def absolute_path?(path)
        Pathname.new(path).absolute?
      end
    else
      def absolute_path?(path)
        path[0] == File::SEPARATOR
      end
    end

    if File::ALT_SEPARATOR
      SEPARATOR_PATTERN = "#{Regexp.quote(File::SEPARATOR)}|#{Regexp.quote(File::ALT_SEPARATOR)}"
    else
      SEPARATOR_PATTERN = "#{Regexp.quote(File::SEPARATOR)}"
    end

    # Public: Check if path is explicitly relative.
    # Starts with "./" or "../".
    #
    # path - String path.
    #
    # Returns true if path is relative, otherwise false.
    def relative_path?(path)
      path =~ /^\.\.?($|#{SEPARATOR_PATTERN})/ ? true : false
    end

    # Internal: Get relative path for root path and subpath.
    #
    # path    - String path
    # subpath - String subpath of path
    #
    # Returns relative String path if subpath is a subpath of path, or nil if
    # subpath is outside of path.
    def split_subpath(path, subpath)
      return '' if path == subpath
      path = File.join(path, '')
      subpath[path.length..-1] if subpath.start_with?(path)
    end

    # Internal: Detect root path and base for file in a set of paths.
    #
    # paths    - Array of String paths
    # filename - String path of file expected to be in one of the paths.
    #
    # Returns [String root, String path]
    def paths_split(paths, filename)
      paths.each do |path|
        if subpath = split_subpath(path, filename)
          return path, subpath
        end
      end
      nil
    end

    # Internal: Get path's extensions.
    #
    # path - String
    #
    # Returns an Array of String extnames.
    def path_extnames(path)
      File.basename(path).scan(/\.[^.]+/)
    end

    # Internal: Match path extnames against available extensions.
    #
    # path       - String
    # extensions - Hash of String extnames to values
    #
    # Returns [String extname, Object value] or nil nothing matched.
    def match_path_extname(path, extensions)
      match = nil
      key = ''
      path_extnames(path).reverse_each do |extname|
        key.prepend(extname)
        if value = extensions[key]
          match = [key.dup, value]
        elsif match
          break
        end
      end
      match
    end

    # Internal: Match paths in a directory against available extensions.
    #
    # path       - String directory
    # basename   - String basename of target file
    # extensions - Hash of String extnames to values
    #
    # Examples
    #
    #     exts = { ".js" => "application/javascript" }
    #     find_matching_path_for_extensions("app/assets", "application", exts)
    #     # => ["app/assets/application.js", "application/javascript"]
    #
    # Returns an Array of [String path, Object value] matches.
    def find_matching_path_for_extensions(path, basename, extensions)
      matches = []
      entries(path).each do |entry|
        extname, value = match_path_extname(entry, extensions)
        if basename == entry.chomp(extname)
          filename = File.join(path, entry)
          matches << [filename, value] if file?(filename)
        end
      end
      matches
    end

    # Internal: Returns all parents for path
    #
    # path - String absolute filename or directory
    # root - String path to stop at (default: system root)
    #
    # Returns an Array of String paths.
    def path_parents(path, root = nil)
      root = "#{root}#{File::SEPARATOR}" if root
      parents = []

      loop do
        parent = File.dirname(path)
        break if parent == path
        break if root && !path.start_with?(root)
        parents << path = parent
      end

      parents
    end

    # Internal: Find target basename checking upwards from path.
    #
    # basename - String filename: ".sprocketsrc"
    # path     - String path to start search: "app/assets/javascripts/app.js"
    # root     - String path to stop at (default: system root)
    #
    # Returns String filename or nil.
    def find_upwards(basename, path, root = nil)
      path_parents(path, root).each do |dir|
        filename = File.join(dir, basename)
        return filename if file?(filename)
      end
      nil
    end

    # Public: Stat all the files under a directory.
    #
    # dir - A String directory
    #
    # Returns an Enumerator of [path, stat].
    def stat_directory(dir)
      return to_enum(__method__, dir) unless block_given?

      entries(dir).each do |entry|
        path = File.join(dir, entry)
        if stat = self.stat(path)
          yield path, stat
        end
      end

      nil
    end

    # Public: Recursive stat all the files under a directory.
    #
    # dir - A String directory
    #
    # Returns an Enumerator of [path, stat].
    def stat_tree(dir, &block)
      return to_enum(__method__, dir) unless block_given?

      stat_directory(dir) do |path, stat|
        yield path, stat

        stat_tree(path, &block) if stat.directory?
      end

      nil
    end

    # Public: Recursive stat all the files under a directory in alphabetical
    # order.
    #
    # dir - A String directory
    #
    # Returns an Enumerator of [path, stat].
    def stat_sorted_tree(dir, &block)
      return to_enum(__method__, dir) unless block_given?

      stat_directory(dir).sort_by do |path, stat|
        stat.directory? ? "#{path}/" : path
      end.each do |path, stat|
        yield path, stat

        stat_sorted_tree(path, &block) if stat.directory?
      end

      nil
    end

    # Public: Write to a file atomically. Useful for situations where you
    # don't want other processes or threads to see half-written files.
    #
    #   Utils.atomic_write('important.file') do |file|
    #     file.write('hello')
    #   end
    #
    # Returns nothing.
    def atomic_write(filename)
      dirname, basename = File.split(filename)
      basename = [
        basename,
        Thread.current.object_id,
        Process.pid,
        rand(1_000_000)
      ].join('.'.freeze)
      tmpname = File.join(dirname, basename)

      File.open(tmpname, 'wb+') do |f|
        yield f
      end

      FileUtils.mv(tmpname, filename)
    ensure
      FileUtils.rm(tmpname) if File.exist?(tmpname)
    end
  end
end
