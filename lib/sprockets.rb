require 'sprockets/version'

module Sprockets
  # Environment
  autoload :Base,                    'sprockets/base'
  autoload :Environment,             'sprockets/environment'
  autoload :Index,                   'sprockets/index'
  autoload :Manifest,                'sprockets/manifest'

  # Assets
  autoload :Asset,                   'sprockets/asset'
  autoload :BundledAsset,            'sprockets/bundled_asset'
  autoload :ProcessedAsset,          'sprockets/processed_asset'
  autoload :StaticAsset,             'sprockets/static_asset'

  # Processing
  autoload :CharsetNormalizer,       'sprockets/charset_normalizer'
  autoload :ClosureCompressor,       'sprockets/closure_compressor'
  autoload :CoffeeScriptTemplate,    'sprockets/coffee_script_template'
  autoload :Context,                 'sprockets/context'
  autoload :DirectiveProcessor,      'sprockets/directive_processor'
  autoload :EcoTemplate,             'sprockets/eco_template'
  autoload :EjsTemplate,             'sprockets/ejs_template'
  autoload :ERBTemplate,             'sprockets/erb_template'
  autoload :JstProcessor,            'sprockets/jst_processor'
  autoload :LessTemplate,            'sprockets/less_template'
  autoload :SafetyColons,            'sprockets/safety_colons'
  autoload :SassCacheStore,          'sprockets/sass_cache_store'
  autoload :SassCompressor,          'sprockets/sass_compressor'
  autoload :SassFunctions,           'sprockets/sass_functions'
  autoload :SassTemplate,            'sprockets/sass_template'
  autoload :ScssTemplate,            'sprockets/sass_template'
  autoload :UglifierCompressor,      'sprockets/uglifier_compressor'
  autoload :YUICompressor,           'sprockets/yui_compressor'

  # Internal utilities
  autoload :ArgumentError,           'sprockets/errors'
  autoload :AssetAttributes,         'sprockets/asset_attributes'
  autoload :CacheWrapper,            'sprockets/cache_wrapper'
  autoload :CircularDependencyError, 'sprockets/errors'
  autoload :ContentTypeMismatch,     'sprockets/errors'
  autoload :EngineError,             'sprockets/errors'
  autoload :Error,                   'sprockets/errors'
  autoload :FileNotFound,            'sprockets/errors'
  autoload :LazyProxy,               'sprockets/lazy_proxy'
  autoload :Utils,                   'sprockets/utils'

  module Cache
    autoload :FileStore, 'sprockets/cache/file_store'
    autoload :MemoryStore, 'sprockets/cache/memory_store'
    autoload :NullStore, 'sprockets/cache/null_store'
  end

  # Extend Sprockets module to provide global registry
  require 'hike'
  require 'sprockets/engines'
  require 'sprockets/mime'
  require 'sprockets/processing'
  require 'sprockets/compressing'
  require 'sprockets/paths'
  extend Engines, Mime, Processing, Compressing, Paths

  @trail             = Hike::Trail.new(File.expand_path('..', __FILE__))
  @mime_types        = {}
  @engines           = {}
  @engine_mime_types = {}
  @preprocessors     = Hash.new { |h, k| h[k] = [] }
  @postprocessors    = Hash.new { |h, k| h[k] = [] }
  @bundle_processors = Hash.new { |h, k| h[k] = [] }
  @compressors       = Hash.new { |h, k| h[k] = {} }

  register_mime_type 'text/css', '.css'
  register_mime_type 'application/javascript', '.js'

  register_preprocessor 'text/css',               DirectiveProcessor
  register_preprocessor 'application/javascript', DirectiveProcessor

  register_postprocessor 'application/javascript', SafetyColons

  register_bundle_processor 'text/css', CharsetNormalizer

  register_compressor 'text/css', :sass, LazyProxy.new { SassCompressor }
  register_compressor 'text/css', :scss, LazyProxy.new { SassCompressor }
  register_compressor 'text/css', :yui, LazyProxy.new { YUICompressor }
  register_compressor 'application/javascript', :closure, LazyProxy.new { ClosureCompressor }
  register_compressor 'application/javascript', :uglifier, UglifierCompressor
  register_compressor 'application/javascript', :uglify, UglifierCompressor
  register_compressor 'application/javascript', :yui, LazyProxy.new { YUICompressor }

  # Mmm, CoffeeScript
  register_engine '.coffee', CoffeeScriptTemplate, mime_type: 'application/javascript'

  # JST engines
  register_engine '.jst',    JstProcessor, mime_type: 'application/javascript'
  register_engine '.eco',    EcoTemplate,  mime_type: 'application/javascript'
  register_engine '.ejs',    EjsTemplate,  mime_type: 'application/javascript'

  # CSS engines
  register_engine '.less',   LessTemplate, mime_type: 'text/css'
  register_engine '.sass',   SassTemplate, mime_type: 'text/css'
  register_engine '.scss',   ScssTemplate, mime_type: 'text/css'

  # Other
  register_engine '.erb',    ERBTemplate
end
