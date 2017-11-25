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
      if File.exist?(path)
        File.stat(path)
      else
        nil
      end
    end

    # Public: Like `File.file?`.
    #
    # path - String file path.
    #
    # Returns true path exists and is a file.
    def file?(path)
      mdata = self.meta_data(path)
      mdata[:file] if mdata
    end

    # Public: Like `File.directory?`.
    #
    # path - String file path.
    #
    # Returns true path exists and is a directory.
    def directory?(path)
      mdata = self.meta_data(path)
      mdata[:directory] if mdata
    end

    # Public: A version of `Dir.entries` that filters out `.` files and `~`
    # swap files.
    #
    # path - String directory path
    #
    # Returns an empty `Array` if the directory does not exist.
    def entries(path)
      mdata = self.meta_data(path)
      if mdata && mdata[:directory]
        mdata[:directory_entries]
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
        path.start_with?(File::SEPARATOR)
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
      return "" if path == subpath
      path = File.join(path, '')
      if subpath.start_with?(path)
        subpath[path.length..-1]
      else
        nil
      end
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
      basename = File.basename(path)

      i = basename.index('.'.freeze)
      while i && i < basename.length - 1
        extname = basename[i..-1]
        if value = extensions[extname]
          return extname, value
        end

        i = basename.index('.'.freeze, i+1)
      end

      nil
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

      self.entries(dir).each do |entry|
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

      self.stat_directory(dir) do |path, stat|
        yield path, stat

        if stat.directory?
          stat_tree(path, &block)
        end
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

      self.stat_directory(dir).sort_by { |path, stat|
        stat.directory? ? "#{path}/" : path
      }.each do |path, stat|
        yield path, stat

        if stat.directory?
          stat_sorted_tree(path, &block)
        end
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
        rand(1000000)
      ].join('.')
      tmpname = File.join(dirname, basename)

      File.open(tmpname, 'wb+') do |f|
        yield f
      end

      File.rename(tmpname, filename)
    ensure
      File.delete(tmpname) if File.exist?(tmpname)
    end

    # Private: Get meta data path from cache
    # if meta data is not in cache or is obsolete it gets updatet.
    # this is meant to be the only access path for file or directory meta data,
    # because accesses are cached and this improves performance multiple times
    # for many and large asset paths.
    #
    # updates meta_data if determined necessary
    #
    # returns: meta_data hash or nil
    #
    # meta_data: see below in update_meta_data

    def meta_data(path)
      # file-meta-data:version:path, update version if meta_data hash contents are changed to invalidate existing cached data
      key = "file-meta-data:1:#{path}"
      meta_data = cache.get(key)
      if meta_data && !meta_data[:file_exist] && meta_data[:last_visited_i] < Sprockets::Environment.start_time_i
        meta_data = update_meta_data(path, key, meta_data)
      elsif meta_data && meta_data[:static] && meta_data[:last_visited_i] < Sprockets::Environment.start_time_i
        meta_data = update_meta_data(path, key, meta_data)
      elsif meta_data && !meta_data[:static]
        meta_data = update_meta_data(path, key, meta_data)
      elsif meta_data.nil?
        meta_data = update_meta_data(path, key, meta_data)
      end
      meta_data
    end

    private

    def update_meta_data(path, key, meta_data)
      fstat = if File.exist?(path)
                File.stat(path)
              else
                nil
              end
      if fstat && (meta_data.nil? || (meta_data && meta_data[:mtime] != fstat.mtime) || (meta_data && meta_data[:static]))
        dentries = nil
        if fstat.directory?
          dentries = Dir.entries(path, :encoding => Encoding.default_internal)
          dentries.reject! { |entry|
            entry.start_with?(".".freeze) ||
            entry.start_with?("..".freeze) ||
            (entry.start_with?("#".freeze) && entry.end_with?("#".freeze)) ||
            entry.end_with?("~".freeze)
          }
          dentries.sort!
        end
        meta_data = {
          directory: fstat.directory?,
          directory_entries: dentries,
          file: fstat.file?,
          file_digest_uri: URIUtils.build_file_digest_uri(path),
          mtime: fstat.mtime,
          size: fstat.size,
          static: static_path?(path),
          stat_digest: self.stat_digest_dir(path, fstat, dentries),
          last_visited_i: Time.now.to_i,
          exist: true
        }
        cache.set(key, meta_data)
      elsif fstat.nil? && !path.start_with?(root)
        meta_data = {
          directory: false,
          directory_entries: nil,
          file: false,
          file_digest_uri: nil,
          mtime: Time.now,
          size: nil,
          static: true,
          stat_digest: nil,
          last_visited_i: Time.now.to_i,
          exist: false
        }
        cache.set(key, meta_data)
      end
      meta_data
    end

    def static_path?(path)
      self.check_modified_paths.each do |mod_path|
        return false if path.start_with?(mod_path)
      end
      true
    end
  end
end
