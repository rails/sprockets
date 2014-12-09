module Sprockets
  # Internal: Used for lazy loading processors.
  #
  #   LazyProcessor.new { CoffeeScriptProcessor }
  #
  class LazyProcessor
    def initialize(&block)
      @block = block
    end

    def unwrap
      @obj ||= @block.call
    end
  end
end
