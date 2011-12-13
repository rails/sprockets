require 'json'
require 'time'

module Sprockets
  class Manifest
    attr_reader :environment, :path, :dir

    def initialize(environment, path)
      @environment = environment
      @path = File.expand_path(path)
      @dir  = File.dirname(path)

      if File.exist?(path)
        @data = JSON.parse(File.read(path))
      else
        @data = {}
      end
    end

    def files
      @data['files'] ||= {}
    end

    def bundles
      @data['bundles'] ||= {}
    end

    def backups_for(logical_path)
      files.select { |filename, attrs|
        attrs['logical_path'] == logical_path &&
          bundles[logical_path] != filename
      }.sort_by { |filename, attrs|
        Time.parse(attrs['mtime'])
      }.reverse
    end

    def compile(logical_path)
      if asset = find_asset(logical_path)
        files[asset.digest_path] = {
          'logical_path' => asset.logical_path,
          'mtime'        => asset.mtime.iso8601,
          'digest'       => asset.digest
        }
        bundles[asset.logical_path] = asset.digest_path

        target = File.join(dir, asset.digest_path)

        if File.exist?(target)
          logger.debug "Skipping #{target}, already exists"
        else
          logger.info "Writing #{target}"
          asset.write_to target
        end

        save
        asset
      end
    end

    def remove(filename)
      logger.warn "Remove #{filename}"
      path = File.join(dir, filename)
      files.delete(filename)
      FileUtils.rm(path) if File.exist?(path)
      save
      nil
    end

    def clean
      self.bundles.keys.each do |logical_path|
        # Get bundles sorted by ctime, newest first
        bundles = backups_for(logical_path)

        # Keep the last 2
        bundles = bundles[2..-1] || []

        # Remove old bundles
        bundles.each { |path, _| remove(path) }
      end
    end

    protected
      def find_asset(logical_path)
        asset = nil
        ms = benchmark do
          asset = environment.find_asset(logical_path)
        end
        logger.warn "Compiled #{logical_path}  (#{ms}ms)"
        asset
      end

      def save
        FileUtils.mkdir_p dir
        File.open(path, 'w') do |f|
          f.write JSON.generate(@data)
        end
      end

    private
      def logger
        environment.logger
      end

      def benchmark
        start_time = Time.now.to_f
        yield
        elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      end
  end
end
