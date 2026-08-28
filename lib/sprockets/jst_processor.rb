# frozen_string_literal: true
module Sprockets
  # Public: JST transformer.
  #
  # Exports server side compiled templates to an object.
  #
  # Name your template "users/show.ejs", "users/new.eco", etc.
  #
  # To accept the default options
  #
  #     environment.register_transformer
  #       'application/javascript+function',
  #       'application/javascript', JstProcessor
  #
  # Change the default namespace.
  #
  #     environment.register_transformer
  #       'application/javascript+function',
  #       'application/javascript', JstProcessor.new(namespace: 'App.templates')
  #
  class JstProcessor
    VERSION = '1'

    def self.default_namespace
      'this.JST'
    end

    # Public: Return singleton instance with default options.
    #
    # Returns JstProcessor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def self.cache_key
      instance.cache_key
    end

    attr_reader :cache_key

    def initialize(namespace: self.class.default_namespace)
      @namespace = namespace.to_s.dup.freeze
      @cache_key = "#{self.class.name}:#{VERSION}:#{@namespace}".freeze
    end

    def call(input)
      data = input[:data].gsub(/$(.)/m, "\\1  ").strip
      key  = input[:name]
      <<-JST
(function() { #{@namespace} || (#{@namespace} = {}); #{@namespace}[#{key.inspect}] = #{data};
}).call(this);
      JST
    end
  end
end
