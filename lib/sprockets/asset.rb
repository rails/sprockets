module Sprockets
  class Asset
    attr_reader :environment, :source_files

    def initialize(environment, source_file)
      @environment  = environment
      @source_files = []
      require(source_file)
    end

    def require(source_file)

    end
  end
end
