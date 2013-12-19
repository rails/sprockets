module Sprockets
  class ERBTemplate < Template
    def self.engine_initialized?
      defined? ::ERB
    end

    def initialize_engine
      require 'erb'
    end

    def render(context)
      engine = ::ERB.new(data, nil, '<>')
      method_name = "__sprockets_#{Thread.current.object_id.abs}"
      klass = (class << context; self; end)
      engine.def_method(klass, method_name, context.pathname.to_s)
      context.send(method_name)
    end
  end
end
