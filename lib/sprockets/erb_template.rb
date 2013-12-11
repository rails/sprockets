require 'tilt'

module Sprockets
  class ERBTemplate < Tilt::Template
    def self.engine_initialized?
      defined? ::ERB
    end

    def initialize_engine
      require_template_library 'erb'
    end

    def prepare
      @outvar = options[:outvar] || '_erbout'
      options[:trim] = '<>' if !(options[:trim] == false) && (options[:trim].nil? || options[:trim] == true)
      @engine = ::ERB.new(data, options[:safe], options[:trim], @outvar)
    end

    def precompiled_template(locals)
      source = @engine.src
      source
    end

    def precompiled_preamble(locals)
      <<-RUBY
        begin
          __original_outvar = #{@outvar} if defined?(#{@outvar})
          #{super}
      RUBY
    end

    def precompiled_postamble(locals)
      <<-RUBY
          #{super}
        ensure
          #{@outvar} = __original_outvar
        end
      RUBY
    end

    def precompiled(locals)
      source, offset = super
      [source, offset + 1]
    end
  end
end
