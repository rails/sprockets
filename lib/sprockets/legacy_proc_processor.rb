module Sprockets
  # Deprecated: Wraps legacy process Procs with new processor call signature.
  #
  # Will be removed in Sprockets 4.x.
  #
  #     LegacyProcProcessor.new(:compress,
  #       proc { |context, data| data.gsub(...) })
  #
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
