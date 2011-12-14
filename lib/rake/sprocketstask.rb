require 'rake'
require 'rake/tasklib'

require 'sprockets'
require 'logger'

module Rake
  class SprocketsTask < Rake::TaskLib
    attr_accessor :name

    attr_accessor :bundle_dir

    attr_accessor :bundles

    attr_accessor :logger

    def environment
      if !@environment.is_a?(Sprockets::Base) && @environment.respond_to?(:call)
        @environment = @environment.call
      else
        @environment
      end
    end

    attr_writer :environment

    def index
      @index ||= environment.index
    end

    def log_level
      @logger.level
    end

    def log_level=(level)
      if level.is_a?(Integer)
        @logger.level = level
      else
        @logger.level = Logger.const_get(level.to_s.upcase)
      end
    end

    def initialize(name = :bundle)
      init(name)
      yield self if block_given?
      define
    end

    def init(name)
      @name         = name
      @environment  = Sprockets::Environment.new(Dir.pwd)
      @logger       = Logger.new($stderr)
      @logger.level = Logger::WARN
    end

    def manifest
      @manifest ||= Sprockets::Manifest.new(index, "#{bundle_dir}/manifest.json")
    end

    def define
      bundles.each do |logical_path|
        task "#{name}:#{logical_path}" do
          with_logger do
            manifest.compile logical_path
          end
        end
      end

      desc name == :bundle ? "Compile asset bundles" : "Compile #{name} bundles"
      task name => bundles.map { |path| "#{name}:#{path}" }

      desc name == :bundle ? "Remove all asset bundles" : "Remove all #{name} bundles"
      task "clobber_#{name}" do
        with_logger do
          manifest.clobber
        end
      end

      task :clobber => ["clobber_#{name}"]

      desc name == :bundle ? "Clean old asset bundles" : "Clean old #{name} bundles"
      task "clean_#{name}" do
        with_logger do
          manifest.clean
        end
      end

      task :clean => ["clean_#{name}"]
    end

    private
      def with_logger
        old_logger = index.logger
        index.logger = @logger
        yield
      ensure
        index.logger = old_logger
      end
  end
end
