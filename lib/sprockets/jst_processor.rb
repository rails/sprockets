module Sprockets
  class JstProcessor < Template
    self.default_mime_type = 'application/javascript'

    def self.default_namespace
      'this.JST'
    end

    def evaluate(scope, locals, &block)
      namespace = self.class.default_namespace
      <<-JST
(function() { #{namespace} || (#{namespace} = {}); #{namespace}[#{scope.logical_path.inspect}] = #{indent(data)};
}).call(this);
      JST
    end

    private
      def indent(string)
        string.gsub(/$(.)/m, "\\1  ").strip
      end
  end
end
