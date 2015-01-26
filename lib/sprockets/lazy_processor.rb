module Sprockets
  # Internal: Used for lazy loading processors.
  #
  #   LazyProcessor.new { CoffeeScriptProcessor }
  #
  class LazyProcessor
    def initialize(name, &block)
      @name  = name.to_s
      @block = block
    end

    attr_reader :name

    def unwrap
      @obj ||= @block.call
    end
  end
end
