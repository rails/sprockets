# frozen_string_literal: true
require 'erb'

class Sprockets::ERBProcessor
  # Public: Return singleton instance with default options.
  #
  # Returns ERBProcessor object.
  def self.instance
    @instance ||= new
  end

  def self.call(input)
    instance.call(input)
  end

  def initialize(&block)
    @block = block
  end

  def call(input)
    engine = ::ERB.new(input[:data], nil, '<>')
    engine.filename = input[:filename]

    context = input[:environment].context_class.new(input)
    klass = (class << context; self; end)
    klass.const_set(:ENV, context.env_proxy)
    klass.class_eval(&@block) if @block

    data = engine.result(context.instance_eval('binding'))
    context.metadata.merge(data: data)
  end
end
