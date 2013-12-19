module Sprockets
  class Template
    attr_reader :data

    def initialize(file, &block)
      @data = block.call(self)
    end
  end
end
