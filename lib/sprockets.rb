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
  register_mime_type 'application/javascript', extensions: ['.js'], charset: EncodingUtils::DETECT_UNICODE
  register_mime_type 'application/json', extensions: ['.json'], charset: EncodingUtils::DETECT_UNICODE
  register_mime_type 'text/css', extensions: ['.css'], charset: EncodingUtils::DETECT_CSS
  register_mime_type 'text/html', extensions: ['.html', '.htm']
  register_mime_type 'text/plain', extensions: ['.txt', '.text']
  register_mime_type 'text/yaml', extensions: ['.yml', '.yaml'], charset: EncodingUtils::DETECT_UNICODE

  # Common image types
  register_mime_type 'image/x-icon', extensions: ['.ico']
  register_mime_type 'image/bmp', extensions: ['.bmp']
  register_mime_type 'image/gif', extensions: ['.gif']
  register_mime_type 'image/webp', extensions: ['.webp']
  register_mime_type 'image/png', extensions: ['.png']
  register_mime_type 'image/jpeg', extensions: ['.jpg', '.jpeg']
  register_mime_type 'image/tiff', extensions: ['.tiff', '.tif']
  register_mime_type 'image/svg+xml', extensions: ['.svg']

  # Common audio/video types
  register_mime_type 'video/webm', extensions: ['.webm']
  register_mime_type 'audio/basic', extensions: ['.snd', '.au']
  register_mime_type 'audio/aiff', extensions: ['.aiff']
  register_mime_type 'audio/mpeg', extensions: ['.mp3', '.mp2', '.m2a', '.m3a']
  register_mime_type 'application/ogg', extensions: ['.ogx']
  register_mime_type 'audio/midi', extensions: ['.midi', '.mid']
  register_mime_type 'video/avi', extensions: ['.avi']
  register_mime_type 'audio/wave', extensions: ['.wav', '.wave']
  register_mime_type 'video/mp4', extensions: ['.mp4', '.m4v']

  # Common font types
  register_mime_type 'application/vnd.ms-fontobject', extensions: ['.eot']
  register_mime_type 'application/x-font-ttf', extensions: ['.ttf']
  register_mime_type 'application/x-font-woff', extensions: ['.woff']

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
