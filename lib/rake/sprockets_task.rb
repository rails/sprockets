require 'rake'
require 'rake/tasklib'

require 'sprockets'
require 'logger'

module Rake
  class SprocketsTask < Rake::TaskLib
    attr_accessor :name

    attr_accessor :environment

    attr_accessor :bundle_dir

    attr_accessor :bundles

    attr_accessor :logger

    def initialize(name = :bundle)
      init(name)
      yield self if block_given?
      @environment.logger       = Logger.new($stderr)
      @environment.logger.level = Logger::INFO
      define
    end

    def init(name)
      @name        = name
      @environment = Sprockets::Environment.new(Dir.pwd)
    end

    def define
      directory bundle_dir

      bundles.each do |logical_path|
        task "#{name}:#{logical_path}" => bundle_dir do
          if asset = environment.find_asset(logical_path)
            target = File.join(bundle_dir, asset.digest_path)
            asset.write_to target
          end
        end
      end

      desc name == :bundle ? "Compile asset bundles" : "Compile #{name} bundles"
      task name => bundles.map { |path| "#{name}:#{path}" }

      desc name == :bundle ? "Remove all asset bundles" : "Remove all #{name} bundles"
      task "clobber_#{name}" do
        rm_r bundle_dir if File.exist?(bundle_dir)
      end

      task :clobber => ["clobber_#{name}"]

      desc name == :bundle ? "Clean old asset bundles" : "Clean old #{name} bundles"
      task "clean_#{name}" do
        files = Dir["#{bundle_dir}/*"]

        bundles.each do |logical_path|
          if asset = environment.find_asset(logical_path)
            target = File.join(bundle_dir, asset.digest_path)
            files.delete target
          end
        end

        groups = {}

        files.each do |filename|
          group = filename.sub(/-[0-9a-f]{7,40}(\.[^.]+)$/, '\1')
          groups[group] ||= []
          groups[group] << filename
        end

        groups.each do |group, bundles|
          # Get bundles sorted by ctime, newest first
          bundles = bundles.sort_by { |fn| File.ctime(fn) }.reverse

          # Keep the last 3
          bundles = bundles[3..-1] || []

          # Remove old assets
          bundles.each { |fn| rm fn }
        end
      end

      task :clean => ["clean_#{name}"]

    end
  end
end
