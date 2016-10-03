# frozen_string_literal: true
require 'json'
require 'time'

require 'concurrent'

require 'sprockets/manifest_utils'

module Sprockets
  # The Manifest logs the contents of assets compiled to a single directory. It
  # records basic attributes about the asset for fast lookup without having to
  # compile. A pointer from each logical path indicates which fingerprinted
  # asset is the current one.
  #
  # The JSON is part of the public API and should be considered stable. This
  # should make it easy to read from other programming languages and processes
  # that don't have sprockets loaded. See `#assets` and `#files` for more
  # infomation about the structure.
  class Manifest
    include ManifestUtils

    attr_reader :environment

    # Create new Manifest associated with an `environment`. `filename` is a full
    # path to the manifest json file. The file may or may not already exist. The
    # dirname of the `filename` will be used to write compiled assets to.
    # Otherwise, if the path is a directory, the filename will default a random
    # ".sprockets-manifest-*.json" file in that directory.
    #
    #   Manifest.new(environment, "./public/assets/manifest.json")
    #
    def initialize(*args)
      if args.first.is_a?(Base) || args.first.nil?
        @environment = args.shift
      end

      @directory, @filename = args[0], args[1]

      # Whether the manifest file is using the old manifest-*.json naming convention
      @legacy_manifest = false

      # Expand paths
      @directory = File.expand_path(@directory) if @directory
      @filename  = File.expand_path(@filename) if @filename

      # If filename is given as the second arg
      if @directory && File.extname(@directory) != ""
        @directory, @filename = nil, @directory
      end

      # Default dir to the directory of the filename
      @directory ||= File.dirname(@filename) if @filename

      # If directory is given w/o filename, pick a random manifest location
      if @directory && @filename.nil?
        @filename = find_directory_manifest(@directory)
      end

      unless @directory && @filename
        raise ArgumentError, "manifest requires output filename"
      end

      data = {}

      begin
        if File.exist?(@filename)
          data = json_decode(File.read(@filename))
        end
      rescue JSON::ParserError => e
        logger.error "#{@filename} is invalid: #{e.class} #{e.message}"
      end

      @data = data
    end

    # Returns String path to manifest.json file.
    attr_reader :filename
    alias_method :path, :filename

    attr_reader :directory
    alias_method :dir, :directory

    # Returns internal assets mapping. Keys are logical paths which
    # map to the latest fingerprinted filename.
    #
    #   Logical path (String): Fingerprint path (String)
    #
    #   { "application.js" => "application-2e8e9a7c6b0aafa0c9bdeec90ea30213.js",
    #     "jquery.js"      => "jquery-ae0908555a245f8266f77df5a8edca2e.js" }
    #
    def assets
      @data['assets'] ||= {}
    end

    # Returns internal file directory listing. Keys are filenames
    # which map to an attributes array.
    #
    #   Fingerprint path (String):
    #     logical_path: Logical path (String)
    #     mtime: ISO8601 mtime (String)
    #     digest: Base64 hex digest (String)
    #
    #  { "application-2e8e9a7c6b0aafa0c9bdeec90ea30213.js" =>
    #      { 'logical_path' => "application.js",
    #        'mtime' => "2011-12-13T21:47:08-06:00",
    #        'digest' => "2e8e9a7c6b0aafa0c9bdeec90ea30213" } }
    #
    def files
      @data['files'] ||= {}
    end

    # Public: Find all assets matching pattern set in environment.
    #
    # Returns Enumerator of Assets.
    def find(*args)
      unless environment
        raise Error, "manifest requires environment for compilation"
      end

      return to_enum(__method__, *args) unless block_given?

      environment = self.environment.cached
      args.flatten.each do |path|
        environment.find_all_linked_assets(path) do |asset|
          yield asset
        end
      end

      nil
    end

    # Public: Find the source of assets by paths.
    #
    # Returns Enumerator of assets file content.
    def find_sources(*args)
      return to_enum(__method__, *args) unless block_given?

      if environment
        find(*args).each do |asset|
          yield asset.source
        end
      else
        args.each do |path|
          yield File.binread(File.join(dir, assets[path]))
        end
      end
    end

    # Export asset to directory. The asset is written to a
    # fingerprinted filename like
    # `application-2e8e9a7c6b0aafa0c9bdeec90ea30213.js`. An entry is
    # also inserted into the manifest file.
    #
    #   export("application.js")
    #
    def export(*args)
      unless environment
        raise Error, "manifest requires environment for compilation"
      end

      filenames            = []
      concurrent_exporters = []
      executor             = Concurrent::FixedThreadPool.new(Concurrent.processor_count)
      number_of_errors     = 0
      last_error           = nil

      find(*args) do |asset|
        mtime = Time.now.iso8601
        files[asset.digest_path] = {
          'logical_path' => asset.logical_path,
          'mtime'        => mtime,
          'size'         => asset.bytesize,
          'digest'       => asset.hexdigest,

          # Deprecated: Remove beta integrity attribute in next release.
          # Callers should DigestUtils.hexdigest_integrity_uri to compute the
          # digest themselves.
          'integrity'    => DigestUtils.hexdigest_integrity_uri(asset.hexdigest)
        }
        assets[asset.logical_path] = asset.digest_path

        target = File.join(dir, asset.digest_path)

        filenames << asset.filename

        asset_exporters_hash = {}

        environment.exporters.each do |mime_type, exporters|
          next unless environment.match_mime_type? asset.content_type, mime_type
          (asset_exporters_hash[asset] ||= Set.new).merge exporters
        end

        asset_exporters_hash.each do |asset, exporters|
          exporters.each do |exporter|

            exporter_instance = exporter.new(environment, asset, target, dir, logger, mtime)

            if exporter == FileExporter || !environment.config[:export_concurrent]
              # FileExporter must be finished before the other exporters
              exporter_instance.call
            else
              # don't execute these yet, we don't know if FileExporter has already run
              concurrent_exporters << Concurrent::Future.new(executor: executor) do
                begin
                  exporter_instance.call
                rescue => e
                  number_of_errors = number_of_errors + 1
                  last_error = e
                end
              end
            end
          end
          concurrent_exporters.each(&:execute)
        end
      end

      # make sure all exporters have finished before returning the main thread
      concurrent_exporters.each(&:wait!)
      if last_error
        logger.info "There have been #{number_of_errors} errors. " +
        "To inspect them, turn off concurrent exporting by invoking env.export_concurrent = false"
        raise last_error
      end
      save

      filenames
    end
    alias_method :compile, :export

    # Removes file from directory and from manifest. `filename` must
    # be the name with any directory path.
    #
    #   manifest.remove("application-2e8e9a7c6b0aafa0c9bdeec90ea30213.js")
    #
    def remove(filename)
      path = File.join(dir, filename)
      gzip = "#{path}.gz"
      logical_path = files[filename]['logical_path']

      if assets[logical_path] == filename
        assets.delete(logical_path)
      end

      files.delete(filename)
      FileUtils.rm(path) if File.exist?(path)
      FileUtils.rm(gzip) if File.exist?(gzip)

      save

      logger.info "Removed #{filename}"

      nil
    end

    # Cleanup old assets in the compile directory. By default it will
    # keep the latest version, 2 backups and any created within the past hour.
    #
    # Examples
    #
    #   To force only 1 backup to be kept, set count=1 and age=0.
    #
    #   To only keep files created within the last 10 minutes, set count=0 and
    #   age=600.
    #
    def clean(count = 2, age = 3600)
      asset_versions = files.group_by { |_, attrs| attrs['logical_path'] }

      asset_versions.each do |logical_path, versions|
        current = assets[logical_path]

        versions.reject { |path, _|
          path == current
        }.sort_by { |_, attrs|
          # Sort by timestamp
          Time.parse(attrs['mtime'])
        }.reverse.each_with_index.drop_while { |(_, attrs), index|
          _age = [0, Time.now - Time.parse(attrs['mtime'])].max
          # Keep if under age or within the count limit
          _age < age || index < count
        }.each { |(path, _), _|
           # Remove old assets
          remove(path)
        }
      end
    end

    # Wipe directive
    def clobber
      FileUtils.rm_r(directory) if File.exist?(directory)
      logger.info "Removed #{directory}"
      nil
    end

    # Persist manfiest back to FS
    def save
      data = json_encode(@data)
      FileUtils.mkdir_p File.dirname(@filename)
      PathUtils.atomic_write(@filename) do |f|
        f.write(data)
      end
    end

    private
      def json_decode(obj)
        JSON.parse(obj, create_additions: false)
      end

      def json_encode(obj)
        JSON.generate(obj)
      end

      def logger
        if environment
          environment.logger
        else
          logger = Logger.new($stderr)
          logger.level = Logger::FATAL
          logger
        end
      end
  end
end
