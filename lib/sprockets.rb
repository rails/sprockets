require 'sprockets/version'

module Sprockets
  # Environment
  autoload :Asset,                   'sprockets/asset'
  autoload :Base,                    'sprockets/base'
  autoload :CachedEnvironment,       'sprockets/cached_environment'
  autoload :Environment,             'sprockets/environment'
  autoload :Manifest,                'sprockets/manifest'

  # Processing
  autoload :Bundle,                  'sprockets/bundle'
  autoload :ClosureCompressor,       'sprockets/closure_compressor'
  autoload :CoffeeScriptTemplate,    'sprockets/coffee_script_template'
  autoload :Context,                 'sprockets/context'
  autoload :DirectiveProcessor,      'sprockets/directive_processor'
  autoload :EcoTemplate,             'sprockets/eco_template'
  autoload :EjsTemplate,             'sprockets/ejs_template'
  autoload :ERBTemplate,             'sprockets/erb_template'
  autoload :JstProcessor,            'sprockets/jst_processor'
  autoload :SassCompressor,          'sprockets/sass_compressor'
  autoload :SassTemplate,            'sprockets/sass_template'
  autoload :ScssTemplate,            'sprockets/sass_template'
  autoload :UglifierCompressor,      'sprockets/uglifier_compressor'
  autoload :YUICompressor,           'sprockets/yui_compressor'

  # Internal utilities
  autoload :ArgumentError,           'sprockets/errors'
  autoload :Cache,                   'sprockets/cache'
  autoload :ContentTypeMismatch,     'sprockets/errors'
  autoload :EncodingUtils,           'sprockets/encoding_utils'
  autoload :Error,                   'sprockets/errors'
  autoload :FileNotFound,            'sprockets/errors'
  autoload :LazyProxy,               'sprockets/lazy_proxy'
  autoload :PathUtils,               'sprockets/path_utils'
  autoload :Utils,                   'sprockets/utils'

  # Extend Sprockets module to provide global registry
  require 'sprockets/engines'
  require 'sprockets/mime'
  require 'sprockets/processing'
  require 'sprockets/compressing'
  require 'sprockets/paths'
  extend Engines, Mime, Processing, Compressing, Paths

  @root              = File.expand_path('..', __FILE__)
  @paths             = []
  @mime_types        = {}
  @mime_exts         = {}
  @engines           = {}
  @engine_extensions = {}
  @preprocessors     = Hash.new { |h, k| h[k] = [] }
  @postprocessors    = Hash.new { |h, k| h[k] = [] }
  @bundle_processors = Hash.new { |h, k| h[k] = [] }
  @compressors       = Hash.new { |h, k| h[k] = {} }

  # Common asset text types
  register_mime_type 'application/javascript', type: :text, extensions: ['.js'], decoder: EncodingUtils.method(:decode_unicode)
  register_mime_type 'application/json', type: :text, extensions: ['.json'], decoder: EncodingUtils.method(:decode_unicode)
  register_mime_type 'application/x-ruby', type: :text, extensions: ['.rb'], decoder: EncodingUtils.method(:decode_unicode)
  register_mime_type 'text/css', type: :text, extensions: ['.css'], decoder: EncodingUtils.method(:decode_css)
  register_mime_type 'text/html', type: :text, extensions: ['.html', '.htm']
  register_mime_type 'text/plain', type: :text, extensions: ['.txt', '.text']
  register_mime_type 'text/yaml', type: :text, extensions: ['.yml', '.yaml'], decoder: EncodingUtils.method(:decode_unicode)

  # Common asset binary types
  register_mime_type 'application/vnd.ms-fontobject', type: :binary, extensions: ['.eot']
  register_mime_type 'application/x-font-ttf', type: :binary, extensions: ['.ttf']
  register_mime_type 'application/x-font-woff', type: :binary, extensions: ['.woff']
  register_mime_type 'image/gif', type: :binary, extensions: ['.gif']
  register_mime_type 'image/jpeg', type: :binary, extensions: ['.jpg', '.jpeg']
  register_mime_type 'image/png', type: :binary, extensions: ['.png']
  register_mime_type 'image/svg+xml', type: :binary, extensions: ['.svg']
  register_mime_type 'image/tiff', type: :binary, extensions: ['.tiff', '.tif']

  register_preprocessor 'text/css', DirectiveProcessor
  register_preprocessor 'application/javascript', DirectiveProcessor

  register_bundle_processor 'application/javascript', Bundle
  register_bundle_processor 'text/css', Bundle

  register_compressor 'text/css', :sass, LazyProxy.new { SassCompressor }
  register_compressor 'text/css', :scss, LazyProxy.new { SassCompressor }
  register_compressor 'text/css', :yui, LazyProxy.new { YUICompressor }
  register_compressor 'application/javascript', :closure, LazyProxy.new { ClosureCompressor }
  register_compressor 'application/javascript', :uglifier, LazyProxy.new { UglifierCompressor }
  register_compressor 'application/javascript', :uglify, LazyProxy.new { UglifierCompressor }
  register_compressor 'application/javascript', :yui, LazyProxy.new { YUICompressor }

  # Mmm, CoffeeScript
  register_engine '.coffee', LazyProxy.new { CoffeeScriptTemplate }, mime_type: 'application/javascript'

  # JST engines
  register_engine '.jst',    LazyProxy.new { JstProcessor }, mime_type: 'application/javascript'
  register_engine '.eco',    LazyProxy.new { EcoTemplate },  mime_type: 'application/javascript'
  register_engine '.ejs',    LazyProxy.new { EjsTemplate },  mime_type: 'application/javascript'

  # CSS engines
  register_engine '.sass',   LazyProxy.new { SassTemplate }, mime_type: 'text/css'
  register_engine '.scss',   LazyProxy.new { ScssTemplate }, mime_type: 'text/css'

  # Other
  register_engine '.erb',    LazyProxy.new { ERBTemplate }
end
