module Sprockets
  module JstProcessor
    def self.call(input)
      data = input[:data].gsub(/$(.)/m, "\\1  ").strip
      <<-JST
(function() { this.JST || (this.JST = {}); this.JST[#{input[:logical_path].inspect}] = #{data};
}).call(this);
      JST
    end
  end
end
