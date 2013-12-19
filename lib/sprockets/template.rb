module Sprockets
  class Template
    attr_reader :data

    class << self
      attr_accessor :default_mime_type
    end

    def initialize(file, &block)
      @data = block.call(self)
    end
  end
end
