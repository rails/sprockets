require 'sprockets/engines'
require 'sprockets/lazy_processor'
require 'sprockets/legacy_proc_processor'
require 'sprockets/legacy_tilt_processor'
require 'sprockets/mime'
require 'sprockets/utils'

module Sprockets
  # `Processing` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Processing
    # Preprocessors are ran before Postprocessors and Engine
    # processors.
    attr_reader :preprocessors

    # Internal: Find and load preprocessors by mime type.
    #
    # mime_type - String MIME type.
    #
    # Returns Array of Procs.
    def unwrap_preprocessors(mime_type)
      preprocessors[mime_type].map do |processor|
        unwrap_processor(processor)
      end
    end

    # Postprocessors are ran after Preprocessors and Engine processors.
    attr_reader :postprocessors

    # Internal: Find and load postprocessors by mime type.
    #
    # mime_type - String MIME type.
    #
    # Returns Array of Procs.
    def unwrap_postprocessors(mime_type)
      postprocessors[mime_type].map do |processor|
        unwrap_processor(processor)
      end
    end

    # Registers a new Preprocessor `klass` for `mime_type`.
    #
    #     register_preprocessor 'text/css', Sprockets::DirectiveProcessor
    #
    # A block can be passed for to create a shorthand processor.
    #
    #     register_preprocessor 'text/css', :my_processor do |context, data|
    #       data.gsub(...)
    #     end
    #
    def register_preprocessor(mime_type, klass, &block)
      mutate_hash_config(:preprocessors, mime_type) do |processors|
        processors.push(wrap_processor(klass, block))
        processors
      end
    end

    # Registers a new Postprocessor `klass` for `mime_type`.
    #
    #     register_postprocessor 'application/javascript', Sprockets::DirectiveProcessor
    #
    # A block can be passed for to create a shorthand processor.
    #
    #     register_postprocessor 'application/javascript', :my_processor do |context, data|
    #       data.gsub(...)
    #     end
    #
    def register_postprocessor(mime_type, klass, proc = nil, &block)
      proc ||= block
      mutate_hash_config(:postprocessors, mime_type) do |processors|
        processors.push(wrap_processor(klass, proc))
        processors
      end
    end

    # Remove Preprocessor `klass` for `mime_type`.
    #
    #     unregister_preprocessor 'text/css', Sprockets::DirectiveProcessor
    #
    def unregister_preprocessor(mime_type, klass)
      if klass.is_a?(String) || klass.is_a?(Symbol)
        klass = preprocessors[mime_type].detect { |cls|
          cls.respond_to?(:name) && cls.name == "Sprockets::LegacyProcProcessor (#{klass})"
        }
      end

      mutate_hash_config(:preprocessors, mime_type) do |processors|
        processors.delete(klass)
        processors
      end
    end

    # Remove Postprocessor `klass` for `mime_type`.
    #
    #     unregister_postprocessor 'text/css', Sprockets::DirectiveProcessor
    #
    def unregister_postprocessor(mime_type, klass)
      if klass.is_a?(String) || klass.is_a?(Symbol)
        klass = postprocessors[mime_type].detect { |cls|
          cls.respond_to?(:name) && cls.name == "Sprockets::LegacyProcProcessor (#{klass})"
        }
      end

      mutate_hash_config(:postprocessors, mime_type) do |processors|
        processors.delete(klass)
        processors
      end
    end

    # Bundle Processors are ran on concatenated assets rather than
    # individual files.
    attr_reader :bundle_processors

    # Internal: Find and load bundle processors by mime type.
    #
    # mime_type - String MIME type.
    #
    # Returns Array of Procs.
    def unwrap_bundle_processors(mime_type)
      bundle_processors[mime_type].map do |processor|
        unwrap_processor(processor)
      end
    end

    # Registers a new Bundle Processor `klass` for `mime_type`.
    #
    #     register_bundle_processor  'application/javascript', Sprockets::DirectiveProcessor
    #
    # A block can be passed for to create a shorthand processor.
    #
    #     register_bundle_processor 'application/javascript', :my_processor do |context, data|
    #       data.gsub(...)
    #     end
    #
    def register_bundle_processor(mime_type, klass, &block)
      mutate_hash_config(:bundle_processors, mime_type) do |processors|
        processors.push(wrap_processor(klass, block))
        processors
      end
    end

    # Remove Bundle Processor `klass` for `mime_type`.
    #
    #     unregister_bundle_processor 'application/javascript', Sprockets::DirectiveProcessor
    #
    def unregister_bundle_processor(mime_type, klass)
      if klass.is_a?(String) || klass.is_a?(Symbol)
        klass = bundle_processors[mime_type].detect { |cls|
          cls.respond_to?(:name) && cls.name == "Sprockets::LegacyProcProcessor (#{klass})"
        }
      end

      mutate_hash_config(:bundle_processors, mime_type) do |processors|
        processors.delete(klass)
        processors
      end
    end

    # Internal: Run processors on filename and data.
    #
    # Returns Hash.
    def process(processors, uri, filename, load_path, name, content_type, data)
      metadata = {}

      input = {
        environment: self,
        cache: cache,
        uri: uri,
        filename: filename,
        load_path: load_path,
        name: name,
        content_type: content_type,
        data: data,
        metadata: metadata
      }

      processors.each do |processor|
        begin
          result = processor.call(input.merge(data: data, metadata: metadata))
          case result
          when NilClass
            # noop
          when Hash
            data = result[:data]
            metadata = metadata.merge(result)
            metadata.delete(:data)
          when String
            data = result
          else
            raise Error, "invalid processor return type: #{result.class}"
          end
        end
      end

      {
        source: data,
        charset: data.encoding.name.downcase,
        length: data.bytesize,
        digest: digest_class.hexdigest(data),
        metadata: metadata
      }
    end

    # Internal: Two dimensional Hash of reducer functions for a given mime type
    # and asset metadata key.
    attr_reader :bundle_reducers

    # Public: Register bundle reducer function.
    #
    # Examples
    #
    #   Sprockets.register_bundle_reducer 'application/javascript', :jshint_errors, [], :+
    #
    #   Sprockets.register_bundle_reducer 'text/css', :selector_count, 0 { |total, count|
    #     total + count
    #   }
    #
    # mime_type - String MIME Type. Use '*/*' applies to all types.
    # key       - Symbol metadata key
    # initial   - Initial memo to pass to the reduce funciton (default: nil)
    # block     - Proc accepting the memo accumulator and current value
    #
    # Returns nothing.
    def register_bundle_reducer(mime_type, key, *args, &block)
      case args.size
      when 0
        reducer = block
      when 1
        if block_given?
          initial = args[0]
          reducer = block
        else
          initial = nil
          reducer = args[0].to_proc
        end
      when 2
        initial = args[0]
        reducer = args[1].to_proc
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 0..2)"
      end

      mutate_hash_config(:bundle_reducers, mime_type) do |reducers|
        reducers.merge(key => [initial, reducer])
      end
    end

    # Internal: Gather all bundle reducer functions for MIME type.
    #
    # mime_type - String MIME type
    #
    # Returns an Array of [initial, reducer_proc] pairs.
    def unwrap_bundle_reducers(mime_type)
      self.bundle_reducers['*/*'].merge(self.bundle_reducers[mime_type])
    end

    # Internal: Run bundle reducers on set of Assets producing a reduced
    # metadata Hash.
    #
    # assets - Array of Assets
    # reducers - Array of [initial, reducer_proc] pairs
    #
    # Returns reduced asset metadata Hash.
    def process_bundle_reducers(assets, reducers)
      initial = {}
      reducers.each do |k, (v, _)|
        initial[k] = v if v
      end
      # Deprecated: For Asset#to_a
      initial[:required_asset_hashes] = []

      assets.reduce(initial) do |h, asset|
        reducers.each do |k, (_, block)|
          # TODO: Avoid creating asset wrapper here
          value = k == :data ? asset.source : asset.metadata[k]
          h[k]  = h.key?(k) ? block.call(h[k], value) : value
        end
        # Deprecated: For Asset#to_a
        h[:required_asset_hashes] << asset.to_hash
        h
      end
    end

    private
      def wrap_processor(klass, proc)
        if !proc
          if klass.class == Sprockets::LazyProcessor || klass.respond_to?(:call)
            klass
          else
            LegacyTiltProcessor.new(klass)
          end
        elsif proc.respond_to?(:arity) && proc.arity == 2
          LegacyProcProcessor.new(klass.to_s, proc)
        else
          proc
        end
      end

      def unwrap_processor(processor)
        processor.respond_to?(:unwrap) ? processor.unwrap : processor
      end
  end
end
