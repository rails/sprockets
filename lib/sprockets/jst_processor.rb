module Sprockets
  # Public: .jst engine.
  #
  # Exports server side compliled templates to an object.
  #
  # Name your template "users/show.ejs.jst", "users/new.eco.jst", etc.
  #
  # To accept the default options
  #
  #     environment.register_engine '.jst',
  #       JstProcessor,
  #       mime_type: 'application/javascript'
  #
  # Change the default namespace.
  #
  #     environment.register_engine '.jst',
  #       JstProcessor.new(namespace: 'App.templates'),
  #       mime_type: 'application/javascript'
  #
  class JstProcessor
    def self.default_namespace
      'this.JST'
    end

    def self.call(*args)
      new.call(*args)
    end

    def initialize(options = {})
      @namespace = options[:namespace] || self.class.default_namespace
    end

    def call(input)
      data = input[:data].gsub(/$(.)/m, "\\1  ").strip
      key = input[:logical_path]
      <<-JST
(function() { #{@namespace} || (#{@namespace} = {}); #{@namespace}[#{key.inspect}] = #{data};
}).call(this);
      JST
    end
  end
end
