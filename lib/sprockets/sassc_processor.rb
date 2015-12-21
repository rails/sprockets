require 'sprockets/sass_processor'
require 'base64'

module Sprockets
  class SasscProcessor < SassProcessor
    def initialize(options = {}, &block)
      @cache_version = options[:cache_version]
      @cache_key = "#{self.class.name}:#{VERSION}:#{Autoload::SassC::VERSION}:#{@cache_version}".freeze
      @importer_class = options[:importer]
      @functions = Module.new do
        include SassProcessor::Functions
        include options[:functions] if options[:functions]
        class_eval(&block) if block_given?
      end
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      options = engine_options(input, context)
      engine = Autoload::SassC::Engine.new(input[:data], options)

      data = Utils.module_include(Autoload::SassC::Script::Functions, @functions) do
        engine.render
      end

      match_data = data.match(/(.*)\n\/\*# sourceMappingURL=data:application\/json;base64,(.+) \*\//m)
      css, map = match_data[1], Base64.decode64(match_data[2])

      map = SourceMapUtils.combine_source_maps(
        input[:metadata][:map],
        change_source(SourceMapUtils.decode_json_source_map(map)["mappings"], input[:source_path])
      )

      context.metadata.merge(data: css, map: map)
    end

    private

    def change_source(mappings, source)
      mappings.each { |m| m[:source] = source }
    end

    def engine_options(input, context)
      {
        filename: input[:filename],
        syntax: self.class.syntax,
        load_paths: input[:environment].paths,
        importer: @importer_class,
        source_map_embed: true,
        source_map_file: '.',
        sprockets: {
          context: context,
          environment: input[:environment],
          dependencies: context.metadata[:dependencies]
        }
      }
    end
  end


  class ScsscProcessor < SasscProcessor
    def self.syntax
      :scss
    end
  end
end
