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
  autoload :HTTPUtils,               'sprockets/http_utils'
  autoload :LazyProcessor,           'sprockets/lazy_processor'
  autoload :PathUtils,               'sprockets/path_utils'
  autoload :Utils,                   'sprockets/utils'

  # Extend Sprockets module to provide global registry
  require 'sprockets/configuration'
  extend Configuration

  @root              = File.expand_path('..', __FILE__).freeze
  @paths             = [].freeze
  @mime_types        = {}.freeze
  @mime_exts         = {}.freeze
  @encodings         = {}.freeze
  @transformers      = Hash.new { |h, k| {}.freeze }.freeze
  @preprocessors     = Hash.new { |h, k| [].freeze }.freeze
  @postprocessors    = Hash.new { |h, k| [].freeze }.freeze
  @bundle_processors = Hash.new { |h, k| [].freeze }.freeze
  @compressors       = Hash.new { |h, k| {}.freeze }.freeze
  @context_class     = Context
  @version           = ''

  # Set the default digest
  require 'digest/sha1'
  @digest_class = Digest::SHA1

  require 'logger'
  @logger = Logger.new($stderr)
  @logger.level = Logger::FATAL

  # Common asset text types
  register_mime_type 'application/javascript', extensions: ['.js'], charset: EncodingUtils::DETECT_UNICODE
  register_mime_type 'application/json', extensions: ['.json'], charset: EncodingUtils::DETECT_UNICODE
  register_mime_type 'text/css', extensions: ['.css'], charset: EncodingUtils::DETECT_CSS
  register_mime_type 'text/html', extensions: ['.html', '.htm'], charset: EncodingUtils::DETECT_HTML
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
  register_mime_type 'application/font-woff', extensions: ['.woff']

  # HTTP content encodings
  register_encoding :deflate, EncodingUtils::DEFLATE
  register_encoding :gzip,    EncodingUtils::GZIP
  register_encoding :base64,  EncodingUtils::BASE64

  register_preprocessor 'text/css', DirectiveProcessor
  register_preprocessor 'application/javascript', DirectiveProcessor

  register_bundle_processor 'application/javascript', Bundle
  register_bundle_processor 'text/css', Bundle

  register_compressor 'text/css', :sass, LazyProcessor.new { SassCompressor }
  register_compressor 'text/css', :scss, LazyProcessor.new { SassCompressor }
  register_compressor 'text/css', :yui, LazyProcessor.new { YUICompressor }
  register_compressor 'application/javascript', :closure, LazyProcessor.new { ClosureCompressor }
  register_compressor 'application/javascript', :uglifier, LazyProcessor.new { UglifierCompressor }
  register_compressor 'application/javascript', :uglify, LazyProcessor.new { UglifierCompressor }
  register_compressor 'application/javascript', :yui, LazyProcessor.new { YUICompressor }

  # Mmm, CoffeeScript
  register_mime_type 'text/coffeescript', extensions: ['.coffee']
  register_transformer 'text/coffeescript', 'application/javascript', LazyProcessor.new { CoffeeScriptTemplate }

  # JST engines
  register_mime_type 'application/jst', extensions: ['.jst']
  register_mime_type 'text/eco', extensions: ['.eco']
  register_mime_type 'text/ejs', extensions: ['.ejs']
  register_transformer 'application/jst', 'application/javascript', LazyProcessor.new { JstProcessor }
  register_transformer 'text/eco', 'application/javascript', LazyProcessor.new { EcoTemplate }
  register_transformer 'text/ejs', 'application/javascript', LazyProcessor.new { EjsTemplate }

  # CSS engines
  register_mime_type 'text/sass', '.sass'
  register_mime_type 'text/scss', '.scss'
  register_transformer 'text/sass', 'text/css', LazyProcessor.new { SassTemplate }
  register_transformer 'text/scss', 'text/css', LazyProcessor.new { ScssTemplate }

  # Other
  register_mime_type 'text/plain+ruby', '.erb'
  register_transformer 'text/plain+ruby', 'text/plain', LazyProcessor.new { ERBTemplate }
end
