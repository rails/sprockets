module Sprockets
  # `Compressing` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Compressing
    attr_reader :compressors

    def register_compressor(mime_type, sym, klass)
      @compressors[mime_type][sym] = klass
    end

    # Return CSS compressor or nil if none is set
    def css_compressor
      if defined? @css_compressor
        unwrap_processor(@css_compressor)
      end
    end

    # Assign a compressor to run on `text/css` assets.
    #
    # The compressor object must respond to `compress`.
    def css_compressor=(compressor)
      unregister_bundle_processor 'text/css', @css_compressor if defined? @css_compressor
      @css_compressor = nil
      return unless compressor

      if compressor.is_a?(Symbol)
        @css_compressor = klass = compressors['text/css'][compressor] || raise(Error, "unknown compressor: #{compressor}")
      elsif compressor.respond_to?(:compress)
        klass = LegacyProcProcessor.new(:css_compressor, proc { |context, data| compressor.compress(data) })
        @css_compressor = :css_compressor
      else
        @css_compressor = klass = compressor
      end

      register_bundle_processor 'text/css', klass
    end

    # Return JS compressor or nil if none is set
    def js_compressor
      if defined? @js_compressor
        unwrap_processor(@js_compressor)
      end
    end

    # Assign a compressor to run on `application/javascript` assets.
    #
    # The compressor object must respond to `compress`.
    def js_compressor=(compressor)
      unregister_bundle_processor 'application/javascript', @js_compressor if defined? @js_compressor
      @js_compressor = nil
      return unless compressor

      if compressor.is_a?(Symbol)
        @js_compressor = klass = compressors['application/javascript'][compressor] || raise(Error, "unknown compressor: #{compressor}")
      elsif compressor.respond_to?(:compress)
        klass = LegacyProcProcessor.new(:js_compressor, proc { |context, data| compressor.compress(data) })
        @js_compressor = :js_compressor
      else
        @js_compressor = klass = compressor
      end

      register_bundle_processor 'application/javascript', klass
    end
  end
end
