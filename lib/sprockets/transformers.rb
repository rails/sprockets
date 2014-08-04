module Sprockets
  module Transformers
    # Public: Two level mapping of a source mime type to a target mime type.
    #
    #   environment.transformers
    #   # => { 'text/coffeescript' => {
    #            'application/javascript' => ConvertCoffeeScriptToJavaScript
    #          }
    #        }
    #
    attr_reader :transformers

    # Public: Register a transformer from and to a mime type.
    #
    # from - String mime type
    # to   - String mime type
    # proc - Callable block that accepts an input Hash.
    #
    # Examples
    #
    #   register_transformer 'text/coffeescript', 'application/javascript',
    #     ConvertCoffeeScriptToJavaScript
    #
    #   register_transformer 'image/svg+xml', 'image/png', ConvertSvgToPng
    #
    # Returns nothing.
    def register_transformer(from, to, proc)
      mutate_hash_config(:transformers, from) do |transformers|
        transformers.merge(to => proc)
      end
    end

    # Internal: Find and load transformer by from and to mime type.
    #
    # from - String mime type
    # to   - String mime type
    #
    # Returns Array of Procs.
    def unwrap_transformer(from, to)
      if processor = transformers[from][to]
        [unwrap_processor(processor)]
      else
        []
      end
    end
  end
end
