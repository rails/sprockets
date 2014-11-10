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

    # Public: Two level mapping of target mime type to source mime type.
    #
    #   environment.inverted_transformers
    #   # => { 'application/javascript' => {
    #            'text/coffeescript' => ConvertCoffeeScriptToJavaScript
    #          }
    #        }
    #
    attr_reader :inverted_transformers

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
      mutate_hash_config(:inverted_transformers, to) do |transformers|
        transformers.merge(from => proc)
      end
    end

    # Internal: Resolve target mime type that the source type should be
    # transformed to.
    #
    # type   - String from mime type
    # accept - String accept type list (default: '*/*')
    #
    # Examples
    #
    #   resolve_transform_type('text/plain', 'text/plain')
    #   # => 'text/plain'
    #
    #   resolve_transform_type('image/svg+xml', 'image/png, image/*')
    #   # => 'image/png'
    #
    #   resolve_transform_type('text/css', 'image/png')
    #   # => nil
    #
    # Returns String mime type or nil is no type satisfied the accept value.
    def resolve_transform_type(type, accept)
      find_best_mime_type_match(accept || '*/*', [type].compact + transformers[type].keys)
    end

    # Internal: Expand accept type list to include possible transformed types.
    #
    # parsed_accepts - Array of accept q values
    #
    # Examples
    #
    #   expand_transform_accepts([['application/javascript', 1.0]])
    #   # => [['application/javascript', 1.0], ['text/coffeescript', 0.8]]
    #
    # Returns an expanded Array of q values.
    def expand_transform_accepts(parsed_accepts)
      accepts = []
      parsed_accepts.each do |(type, q)|
        accepts.push([type, q])
        inverted_transformers[type].keys.each do |subtype|
          accepts.push([subtype, q * 0.8])
        end
      end
      accepts
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
