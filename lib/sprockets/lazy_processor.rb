module Sprockets
  # Internal: Used for lazy loading processors.
  #
  #   LazyProcessor.new { CoffeeScriptTemplate }
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
