require 'sprockets/digest_utils'
require 'sprockets/path_utils'

module Sprockets
  # Internal: Crossover of path and digest utilities functions.
  module PathDigestUtils
    include DigestUtils, PathUtils

    # Internal: Compute digest for file stat.
    #
    # path - String filename
    # stat - File::Stat
    #
    # Returns String digest bytes.
    def stat_digest(path, stat)
      if stat.directory?
        # If its a directive, digest the list of filenames
        digest_class.digest(self.entries(path).join(','))
      elsif stat.file?
        # If its a file, digest the contents
        digest_class.file(path.to_s).digest
      else
        raise TypeError, "stat was not a directory or file: #{stat.ftype}"
      end
    end

    # this method is needed for meta_data caching, stat_digest is cached
    # otherwise, if self.entries gets called, like in stat_digest, it may call back to
    # meta_data and loop until stack limit is reached
    def stat_digest_dir(path, stat, dentries = [])
      if stat.directory?
        # If its a directive, digest the list of filenames
        digest_class.digest(dentries.join(','))
      elsif stat.file?
        # If its a file, digest the contents
        digest_class.file(path.to_s).digest
      else
        raise TypeError, "stat was not a directory or file: #{stat.ftype}"
      end
    end

    # Internal: Compute digest for path.
    #
    # path - String filename or directory path.
    #
    # Returns String digest bytes or nil.
    def file_digest(path)
      if stat = self.stat(path)
        self.stat_digest(path, stat)
      end
    end

    # Internal: Compute digest for a set of paths.
    #
    # paths - Array of filename or directory paths.
    #
    # Returns String digest bytes.
    def files_digest(paths)
      self.digest(paths.map { |path| self.file_digest(path) })
    end
  end
end
