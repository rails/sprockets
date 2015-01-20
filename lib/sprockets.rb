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
  autoload :CoffeeScriptProcessor,   'sprockets/coffee_script_processor'
  autoload :CoffeeScriptTemplate,    'sprockets/coffee_script_template'
  autoload :Context,                 'sprockets/context'
  autoload :DirectiveProcessor,      'sprockets/directive_processor'
  autoload :EcoProcessor,            'sprockets/eco_processor'
  autoload :EcoTemplate,             'sprockets/eco_template'
  autoload :EjsProcessor,            'sprockets/ejs_processor'
  autoload :EjsTemplate,             'sprockets/ejs_template'
  autoload :ERBProcessor,            'sprockets/erb_processor'
  autoload :ERBTemplate,             'sprockets/erb_template'
  autoload :JstProcessor,            'sprockets/jst_processor'
  autoload :SassCompressor,          'sprockets/sass_compressor'
  autoload :SassProcessor,           'sprockets/sass_processor'
  autoload :SassTemplate,            'sprockets/sass_template'
  autoload :ScssProcessor,           'sprockets/sass_processor'
  autoload :ScssTemplate,            'sprockets/sass_template'
  autoload :UglifierCompressor,      'sprockets/uglifier_compressor'
  autoload :YUICompressor,           'sprockets/yui_compressor'

  # Internal utilities
  autoload :ArgumentError,           'sprockets/errors'
  autoload :Cache,                   'sprockets/cache'
  autoload :ContentTypeMismatch,     'sprockets/errors'
  autoload :DigestUtils,             'sprockets/digest_utils'
  autoload :EncodingUtils,           'sprockets/encoding_utils'
  autoload :Error,                   'sprockets/errors'
  autoload :FileNotFound,            'sprockets/errors'
  autoload :HTTPUtils,               'sprockets/http_utils'
  autoload :LazyProcessor,           'sprockets/lazy_processor'
  autoload :PathUtils,               'sprockets/path_utils'
  autoload :Utils,                   'sprockets/utils'

  # Extend Sprockets module to provide global registry
  require 'sprockets/configuration'
  require 'sprockets/context'
  require 'digest/sha2'
  extend Configuration

  self.config = {
    bundle_processors: Hash.new { |h, k| [].freeze }.freeze,
    bundle_reducers: Hash.new { |h, k| {}.freeze }.freeze,
    dependencies: Set.new.freeze,
    dependency_resolvers: {}.freeze,
    compressors: Hash.new { |h, k| {}.freeze }.freeze,
    digest_class: Digest::SHA256,
    encodings: {}.freeze,
    engine_mime_types: {}.freeze,
    engines: {}.freeze,
    inverted_transformers: Hash.new { |h, k| {}.freeze }.freeze,
    mime_exts: {}.freeze,
    mime_types: {}.freeze,
    paths: [].freeze,
    postprocessors: Hash.new { |h, k| [].freeze }.freeze,
    preprocessors: Hash.new { |h, k| [].freeze }.freeze,
    processor_dependency_uris: {}.freeze,
    inverted_processor_dependency_uris: {}.freeze,
    root: File.expand_path('..', __FILE__).freeze,
    transformers: Hash.new { |h, k| {}.freeze }.freeze,
    version: ""
  }.freeze

  @context_class = Context

  require 'logger'
  @logger = Logger.new($stderr)
  @logger.level = Logger::FATAL

  # Common asset text types
  register_mime_type 'application/javascript', extensions: ['.js'], charset: :unicode
  register_mime_type 'application/json', extensions: ['.json'], charset: :unicode
  register_mime_type 'application/xml', extensions: ['.xml']
  register_mime_type 'text/css', extensions: ['.css'], charset: :css
  register_mime_type 'text/html', extensions: ['.html', '.htm'], charset: :html
  register_mime_type 'text/plain', extensions: ['.txt', '.text']
  register_mime_type 'text/yaml', extensions: ['.yml', '.yaml'], charset: :unicode

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

  require 'sprockets/directive_processor'
  register_preprocessor 'text/css', DirectiveProcessor.new(
    comments: ["//", ["/*", "*/"]]
  )
  register_preprocessor 'application/javascript', DirectiveProcessor.new(
    comments: ["//", ["/*", "*/"]] + ["#", ["###", "###"]]
  )

  require 'sprockets/bundle'
  register_bundle_processor 'application/javascript', Bundle
  register_bundle_processor 'text/css', Bundle

  register_bundle_metadata_reducer '*/*', :data, :+
  register_bundle_metadata_reducer 'application/javascript', :data, Utils.method(:concat_javascript_sources)
  register_bundle_metadata_reducer '*/*', :links, :+

  register_compressor 'text/css', :sass, LazyProcessor.new { SassCompressor }
  register_compressor 'text/css', :scss, LazyProcessor.new { SassCompressor }
  register_compressor 'text/css', :yui, LazyProcessor.new { YUICompressor }
  register_compressor 'application/javascript', :closure, LazyProcessor.new { ClosureCompressor }
  register_compressor 'application/javascript', :uglifier, LazyProcessor.new { UglifierCompressor }
  register_compressor 'application/javascript', :uglify, LazyProcessor.new { UglifierCompressor }
  register_compressor 'application/javascript', :yui, LazyProcessor.new { YUICompressor }

  # Mmm, CoffeeScript
  register_mime_type 'text/coffeescript', extensions: ['.coffee']
  register_engine '.coffee', LazyProcessor.new { CoffeeScriptProcessor }, mime_type: 'application/javascript'

  # JST engines
  register_mime_type 'text/eco', extensions: ['.eco']
  register_mime_type 'text/ejs', extensions: ['.ejs']
  register_engine '.jst',    LazyProcessor.new { JstProcessor }, mime_type: 'application/javascript'
  register_engine '.eco',    LazyProcessor.new { EcoProcessor },  mime_type: 'application/javascript'
  register_engine '.ejs',    LazyProcessor.new { EjsProcessor },  mime_type: 'application/javascript'

  # CSS engines
  register_mime_type 'text/sass', extensions: ['.sass']
  register_mime_type 'text/scss', extensions: ['.scss']
  register_engine '.sass',   LazyProcessor.new { SassProcessor }, mime_type: 'text/css'
  register_engine '.scss',   LazyProcessor.new { ScssProcessor }, mime_type: 'text/css'

  # Other
  register_engine '.erb',    LazyProcessor.new { ERBProcessor }, mime_type: 'text/plain'

  register_dependency_resolver 'sprockets-version' do
    VERSION
  end
  register_dependency_resolver 'environment-version' do |env|
    env.version
  end
  register_dependency_resolver 'environment-paths' do |env|
    env.paths
  end
  register_dependency_resolver 'file-digest' do |env, str|
    env.file_digest(env.parse_file_digest_uri(str))
  end
  register_dependency_resolver 'processor' do |env, str|
    env.resolve_processor_cache_key_uri(str)
  end

  depend_on 'sprockets-version'
  depend_on 'environment-version'
  depend_on 'environment-paths'
end
