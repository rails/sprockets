require 'sprockets/autoload'
require 'sprockets/path_utils'

module Sprockets
  class BabelProcessor
    VERSION = '1'

    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def initialize(options = {})
      @options = options.merge({
        'blacklist' => (options['blacklist'] || []) + ['useStrict'],
        'sourceMap' => false
      }).freeze

      @cache_key = [
        self.class.name,
        Autoload::Babel::Transpiler::VERSION,
        Autoload::Babel::Source::VERSION,
        VERSION,
        @options
      ].freeze
    end

    def call(input)
      data = input[:data]

      result = input[:cache].fetch(@cache_key + [data]) do
        Autoload::Babel::Transpiler.transform(data, @options.merge(
          'sourceRoot' => input[:load_path],
          'moduleRoot' => '',
          'filename' => input[:filename],
          'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename])
        ))
      end

      result['code']
    end
  end
end
