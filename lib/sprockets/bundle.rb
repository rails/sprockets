module Sprockets
  class Bundle
    def self.call(input)
      new.call(input)
    end

    def call(input)
      nil
    end
  end
end
