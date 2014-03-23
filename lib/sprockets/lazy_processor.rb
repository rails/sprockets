module Sprockets
  class LazyProcessor
    def initialize(&block)
      @block = block
      @proc  = nil
    end

    def call(*args)
      @proc ||= @block.call
      @proc.call(*args)
    end
  end
end
