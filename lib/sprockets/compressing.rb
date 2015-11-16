require 'sprockets/utils'

module Sprockets
  # `Compressing` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Compressing
    include Utils

    def compressors
      config[:compressors]
    end

    def register_compressor(mime_type, sym, klass)
      self.config = hash_reassoc(config, :compressors, mime_type) do |compressors|
        compressors[sym] = klass
        compressors
      end
    end

    # Return CSS compressor or nil if none is set
    def css_compressor
      @css_compressor if defined? @css_compressor
    end

    # Assign a compressor to run on `text/css` assets.
    #
    # The compressor object must respond to `compress`.
    def css_compressor=(compressor)
      unregister_bundle_processor 'text/css', @css_compressor if defined? @css_compressor
      @css_compressor = nil
      return unless compressor

      if compressor.is_a?(Symbol)
        @css_compressor = klass = config[:compressors]['text/css'][compressor] || fail(Error, "unknown compressor: #{compressor}")
      elsif compressor.respond_to?(:compress)
        klass = proc { |input| compressor.compress(input[:data]) }
        @css_compressor = :css_compressor
      else
        @css_compressor = klass = compressor
      end

      register_bundle_processor 'text/css', klass
    end

    # Return JS compressor or nil if none is set
    def js_compressor
      @js_compressor if defined? @js_compressor
    end

    # Assign a compressor to run on `application/javascript` assets.
    #
    # The compressor object must respond to `compress`.
    def js_compressor=(compressor)
      unregister_bundle_processor 'application/javascript', @js_compressor if defined? @js_compressor
      @js_compressor = nil
      return unless compressor

      if compressor.is_a?(Symbol)
        @js_compressor = klass = config[:compressors]['application/javascript'][compressor] || fail(Error, "unknown compressor: #{compressor}")
      elsif compressor.respond_to?(:compress)
        klass = proc { |input| compressor.compress(input[:data]) }
        @js_compressor = :js_compressor
      else
        @js_compressor = klass = compressor
      end

      register_bundle_processor 'application/javascript', klass
    end
  end
end
