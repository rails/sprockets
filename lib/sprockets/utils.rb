require 'digest/sha1'
require 'fileutils'
require 'pathname'
require 'sprockets/errors'
require 'tempfile'

module Sprockets
  # `Utils`, we didn't know where else to put it!
  module Utils
    extend self

    # Define UTF-8 BOM pattern matcher.
    # Avoid using a Regexp literal because it inheirts the files
    # encoding and we want to avoid syntax errors in other interpreters.
    UTF8_BOM_PATTERN = Regexp.new("\\A\uFEFF".encode('utf-8'))

    # Internal: Read unicode file respecting BOM.
    #
    # Rreturns String or raises an EncodingError.
    def read_unicode(filename, external_encoding = Encoding.default_external)
      Pathname.new(filename).open("r:#{external_encoding}") do |f|
        f.read.tap do |data|
          # Eager validate the file's encoding. In most cases we
          # expect it to be UTF-8 unless `default_external` is set to
          # something else. An error is usually raised if the file is
          # saved as UTF-16 when we expected UTF-8.
          if !data.valid_encoding?
            raise EncodingError, "#{filename} has a invalid " +
              "#{data.encoding} byte sequence"

            # If the file is UTF-8 and theres a BOM, strip it for safe concatenation.
          elsif data.encoding.name == "UTF-8" && data =~ UTF8_BOM_PATTERN
            data.sub!(UTF8_BOM_PATTERN, "")
          end
        end
      end
    end

    # Internal: Write to a file atomically. Useful for situations where you
    # don't want other processes or threads to see half-written files.
    #
    #   Utils.atomic_write('important.file') do |file|
    #     file.write('hello')
    #   end
    #
    # If your temp directory is not on the same filesystem as the file you're
    # trying to write, you can provide a different temporary directory.
    #
    #   Utils.atomic_write('/data/something.important', '/data/tmp') do |file|
    #     file.write('hello')
    #   end
    #
    # Taken from ActiveSupport.
    #
    # https://github.com/rails/rails/blob/master/
    #   activesupport/lib/active_support/core_ext/file/atomic.rb
    def atomic_write(file_name, temp_dir = Dir.tmpdir)
      temp_file = Tempfile.new(File.basename(file_name), temp_dir)
      temp_file.binmode
      yield temp_file
      temp_file.close

      if File.exist?(file_name)
        # Get original file permissions
        old_stat = File.stat(file_name)
      else
        # If not possible, probe which are the default permissions in the
        # destination directory.
        old_stat = probe_stat_in(File.dirname(file_name))
      end

      # Overwrite original file with temp file
      FileUtils.mv(temp_file.path, file_name)

      # Set correct permissions on new file
      begin
        File.chown(old_stat.uid, old_stat.gid, file_name)
        # This operation will affect filesystem ACL's
        File.chmod(old_stat.mode, file_name)
      rescue Errno::EPERM
        # Changing file ownership failed, moving on.
      end
    end

    # Internal: Taken from ActiveSupport.
    #
    # https://github.com/rails/rails/blob/master/
    #   activesupport/lib/active_support/core_ext/file/atomic.rb
    def probe_stat_in(dir)
      basename = [
        '.permissions_check',
        Thread.current.object_id,
        Process.pid,
        rand(1000000)
      ].join('.')

      file_name = File.join(dir, basename)
      FileUtils.touch(file_name)
      File.stat(file_name)
    ensure
      FileUtils.rm_f(file_name) if file_name
    end

    # Prepends a leading "." to an extension if its missing.
    #
    #     normalize_extension("js")
    #     # => ".js"
    #
    #     normalize_extension(".css")
    #     # => ".css"
    #
    def normalize_extension(extension)
      extension = extension.to_s
      if extension[/^\./]
        extension
      else
        ".#{extension}"
      end
    end

    # Internal: Generate a hexdigest for a nested JSON serializable object.
    #
    # obj    - A JSON serializable object.
    # digest - Digest instance to modify
    #
    # Returns a String SHA1 digest of the object.
    def hexdigest(obj, digest = ::Digest::SHA1.new)
      case obj
      when String, Symbol, Integer
        digest.update "#{obj.class}"
        digest.update "#{obj}"
      when TrueClass, FalseClass, NilClass
        digest.update "#{obj.class}"
      when Array
        digest.update "#{obj.class}"
        obj.each do |e|
          hexdigest(e, digest)
        end
      when Hash
        digest.update "#{obj.class}"
        obj.map { |(k, v)| hexdigest([k, v]) }.sort.each do |e|
          digest.update(e)
        end
      else
        raise TypeError, "can't convert #{obj.inspect} into String"
      end

      digest.hexdigest
    end
  end
end
