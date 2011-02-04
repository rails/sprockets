module Sprockets
  class Context
    attr_reader :pathname

    def initialize(pathname = nil)
      @pathname = pathname
    end
  end
end
