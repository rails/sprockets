require 'tilt'

module Sprockets
  class JstProcessor < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def prepare
    end

    def evaluate(scope, locals, &block)
      <<-JST
(function() {
  this.JST || (this.JST = {});
  this.JST[#{scope.logical_path.inspect}] = #{indent(data)};
}).call(this);
      JST
    end

    private
      def indent(string)
        string.gsub(/$(.)/m, "\\1  ").strip
      end
  end
end
