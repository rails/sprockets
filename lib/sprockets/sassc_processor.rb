require 'sprockets/sassc_importer'
require 'sprockets/sass_processor'
require 'base64'

module Sprockets
  class SasscProcessor < SassProcessor
    def initialize(options = {}, &block)
      @cache_version = options[:cache_version]
      @cache_key = "#{self.class.name}:#{VERSION}:#{Autoload::SassC::VERSION}:#{@cache_version}".freeze
      @importer_class = options[:importer] || SasscImporter
      @functions = Module.new do
        include SassProcessor::Functions
        include Functions
        include options[:functions] if options[:functions]
        class_eval(&block) if block_given?
      end
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      options = {
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

      engine = Autoload::SassC::Engine.new(input[:data], options)

      data = Utils.module_include(Autoload::SassC::Script::Functions, @functions) do
        engine.render
      end

      match_data = data.match(/(.*)\n\/\*# sourceMappingURL=data:application\/json;base64,(.+) \*\//m)
      css, map = match_data[1], Base64.decode64(match_data[2])

      map = SourceMapUtils.combine_source_maps(
        input[:metadata][:map],
        SourceMapUtils.decode_json_source_map(map)["mappings"]
      )

      context.metadata.merge(data: css, map: map)
    end

    module Functions
      def asset_path(path, options = {})
        path = path.value

        path, _, query, fragment = URI.split(path)[5..8]
        path     = sprockets_context.asset_path(path, options)
        query    = "?#{query}" if query
        fragment = "##{fragment}" if fragment

        Autoload::SassC::Script::String.new("#{path}#{query}#{fragment}", :string)
      end

      def asset_url(path, options = {})
        Autoload::SassC::Script::String.new("url(#{asset_path(path, options).value})")
      end

      def asset_data_url(path)
        url = sprockets_context.asset_data_uri(path.value)
        Autoload::SassC::Script::String.new("url(" + url + ")")
      end
    end
  end

  class ScsscProcessor < SasscProcessor
    def self.syntax
      :scss
    end
  end
end
