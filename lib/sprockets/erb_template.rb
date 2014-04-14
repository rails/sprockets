require 'erb'

module Sprockets
  class ERBTemplate
    def self.call(input)
      new.call(input)
    end

    def call(input)
      engine = ::ERB.new(input[:data], nil, '<>')
      method_name = "__sprockets_#{Thread.current.object_id.abs}"
      context = input[:environment].context_class.new(input)
      klass = (class << context; self; end)
      engine.def_method(klass, method_name, input[:filename])
      data = context.send(method_name)
      context.to_hash.merge(data: data)
    end
  end
end
