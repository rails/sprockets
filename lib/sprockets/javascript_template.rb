require 'tilt'

module Sprockets
  class JavascriptTemplate < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def initialize_engine
      return if "".respond_to?(:to_json)
      require_template_library 'json'
    end

    def prepare
      @template = data.to_json
    end

    def evaluate(scope, locals, &block)
      if scope.respond_to?(:logical_path) && scope.logical_path
        name = scope.logical_path
      else
        name = File.basename(file)
      end

      <<-EOS
(function() {
  if (!window.templates) window.templates = {};
  window.templates[#{name.to_json}] = #{@template};
})();
      EOS
    end
  end
end
