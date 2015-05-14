require 'sprockets/autoload'
require 'sprockets/source_map_utils'

module Sprockets
  # Processor engine class for the CoffeeScript compiler.
  # Depends on the `coffee-script` and `coffee-script-source` gems.
  #
  # For more infomation see:
  #
  #   https://github.com/josh/ruby-coffee-script
  #
  module CoffeeScriptProcessor
    VERSION = '2'

    def self.cache_key
      @cache_key ||= "#{name}:#{Autoload::CoffeeScript::Source.version}:#{VERSION}".freeze
    end

    def self.call(input)
      data = input[:data]

      js, map = input[:cache].fetch([self.cache_key, data]) do
        result = Autoload::CoffeeScript.compile(data, sourceMap: true, sourceFiles: [input[:source_path]])
        [result['js'], SourceMapUtils.decode_json_source_map(result['v3SourceMap'])['mappings']]
      end

      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)
      { data: js, map: map }
    end
  end
end
