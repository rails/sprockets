module Sprockets
  class Template
    attr_reader :data, :file

    @engine_initialized = false
    class << self
      attr_accessor :engine_initialized
      alias engine_initialized? engine_initialized

      attr_accessor :default_mime_type
    end

    def initialize(file, &block)
      @file = file

      if !self.class.engine_initialized?
        initialize_engine if respond_to?(:initialize_engine)
        self.class.engine_initialized = true
      end

      @data = block.call(self)

      prepare if respond_to?(:prepare)
    end
  end
end
