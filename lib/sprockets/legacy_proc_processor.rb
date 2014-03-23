module Sprockets
  class LegacyProcProcessor
    def initialize(name, proc)
      @name = name
      @proc = proc
    end

    def name
      "Sprockets::LegacyProcProcessor (#{@name})"
    end

    def to_s
      name
    end

    def call(input)
      @proc.call(input[:context], input[:data])
    end
  end
end
