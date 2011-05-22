require 'logger'
require 'tilt'

module Sprockets
  module Notifier
    class << self
      attr_accessor :stderr
    end

    self.stderr = Logger.new($stderr)

    def self.notify(logger = stderr)
      if defined?(Rails) && Rails::VERSION::STRING.match(/^3\.1\.0\.beta/)
        logger.warn "WARNING: Sprockets #{Sprockets::VERSION} is incompatible with Rails #{Rails::VERSION::STRING}. Please upgrade to Rails 3.1.0.rc1 or higher."
      end

      if Tilt::VERSION == '1.3'
        logger.warn "WARNING: Sprockets #{Sprockets::VERSION} is incompatible with Tilt 1.3. Please upgrade to Tilt 1.3.1 or higher."
      end
    end
  end
end
