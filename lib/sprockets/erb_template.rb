module Sprockets
  module ERBTemplate
    def self.call(input)
      require 'erb' unless defined? ::ERB
      engine = ::ERB.new(input[:data], nil, '<>')
      method_name = "__sprockets_#{Thread.current.object_id.abs}"
      context = input[:context]
      klass = (class << context; self; end)
      engine.def_method(klass, method_name, input[:filename])
      context.send(method_name)
    end
  end
end
