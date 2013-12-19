module Sprockets
  class ERBTemplate < Template
    def self.engine_initialized?
      defined? ::ERB
    end

    def initialize_engine
      require 'erb'
    end

    def evaluate(scope, locals, &block)
      engine = ::ERB.new(data, nil, '<>')
      method_name = "__sprockets_#{Thread.current.object_id.abs}"
      klass = (class << scope; self; end)
      engine.def_method(klass, method_name, file)
      scope.send(method_name)
    end
  end
end
