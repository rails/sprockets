require 'sprockets/autoload'
require 'sprockets/path_utils'
require 'sprockets/source_map_utils'
require 'json'

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
        'sourceMap' => true
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

      result = input[:cache].fetch(@cache_key + [input[:filename]] + [data]) do
        opts = {
          'sourceRoot' => input[:load_path],
          'moduleRoot' => nil,
          'filename' => input[:filename],
          'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename]),
          'sourceFileName' => input[:source_path]
        }.merge(@options)

        if opts['moduleIds'] && opts['moduleRoot']
          opts['moduleId'] ||= File.join(opts['moduleRoot'], input[:name])
        elsif opts['moduleIds']
          opts['moduleId'] ||= input[:name]
        end
        Autoload::Babel::Transpiler.transform(data, opts)
      end

      map = SourceMapUtils.decode_json_source_map(JSON.generate(result['map']))
      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map["mappings"])

      { data: result['code'], map: map }
    end
  end
end
