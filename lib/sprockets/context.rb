require 'pathname'
require 'rack/utils'
require 'set'
require 'sprockets/errors'

module Sprockets
  # Deprecated: `Context` provides helper methods to all `Template` processors.
  # They are typically accessed by ERB templates. You can mix in custom helpers
  # by injecting them into `Environment#context_class`. Do not mix them into
  # `Context` directly.
  #
  #     environment.context_class.class_eval do
  #       include MyHelper
  #       def asset_url; end
  #     end
  #
  #     <%= asset_url "foo.png" %>
  #
  # The `Context` also collects dependencies declared by
  # assets. See `DirectiveProcessor` for an example of this.
  class Context
    attr_reader :environment, :filename, :pathname

    # Deprecated
    attr_accessor :__LINE__

    def initialize(input)
      @environment  = input[:environment]
      @metadata     = input[:metadata]
      @load_path    = input[:load_path]
      @logical_path = input[:name]
      @filename     = input[:filename]
      @dirname      = File.dirname(@filename)
      @pathname     = Pathname.new(@filename)
      @content_type = input[:content_type]

      @required         = Set.new(@metadata[:required])
      @stubbed          = Set.new(@metadata[:stubbed])
      @links            = Set.new(@metadata[:links])
      @dependency_paths = Set.new(@metadata[:dependency_paths])
    end

    def metadata
      { required: @required,
        stubbed: @stubbed,
        links: @links,
        dependency_paths: @dependency_paths }
    end

    # Returns the environment path that contains the file.
    #
    # If `app/javascripts` and `app/stylesheets` are in your path, and
    # current file is `app/javascripts/foo/bar.js`, `load_path` would
    # return `app/javascripts`.
    attr_reader :load_path
    alias_method :root_path, :load_path

    # Returns logical path without any file extensions.
    #
    #     'app/javascripts/application.js'
    #     # => 'application'
    #
    attr_reader :logical_path

    # Returns content type of file
    #
    #     'application/javascript'
    #     'text/css'
    #
    attr_reader :content_type

    # Internal
    # TODO: Cleanup relative resolver logic shared between directive processor.
    def _resolve(method, path, options = {})
      options[:content_type] = self.content_type if options[:content_type] == :self
      options[:accept] = options.delete(:content_type)

      if environment.absolute_path?(path)
        filename = path
      elsif environment.relative_path?(path)
        path = File.expand_path(path, @dirname)
        if logical_path = @environment.split_subpath(load_path, path)
          if filename = environment.send(method, logical_path, options.merge(load_paths: [load_path]))
            accept = options[:accept]
            message = "couldn't find file '#{logical_path}' under '#{load_path}'"
            message << " with type '#{accept}'" if accept
            raise FileNotFound, message
          end
        else
          raise FileOutsidePaths, "#{path} isn't under path: #{load_path}"
        end
      else
        filename = environment.send(method, path, options)
      end

      if filename
        filename
      else
        accept = options[:accept]
        message = "couldn't find file '#{path}'"
        message << " with type '#{accept}'" if accept
        raise FileNotFound, message
      end
    end

    # Given a logical path, `resolve` will find and return the fully
    # expanded path. Relative paths will also be resolved. An optional
    # `:content_type` restriction can be supplied to restrict the
    # search.
    #
    #     resolve("foo.js")
    #     # => "/path/to/app/javascripts/foo.js"
    #
    #     resolve("./bar.js")
    #     # => "/path/to/app/javascripts/bar.js"
    #
    def resolve(path, options = {})
      _resolve(:resolve, path, options)
    end

    def locate(path, options = {})
      _resolve(:locate, path, options)
    end

    # `depend_on` allows you to state a dependency on a file without
    # including it.
    #
    # This is used for caching purposes. Any changes made to
    # the dependency file with invalidate the cache of the
    # source file.
    def depend_on(path)
      @dependency_paths << resolve(path).to_s
      nil
    end

    # `depend_on_asset` allows you to state an asset dependency
    # without including it.
    #
    # This is used for caching purposes. Any changes that would
    # invalidate the dependency asset will invalidate the source
    # file. Unlike `depend_on`, this will include recursively include
    # the target asset's dependencies.
    def depend_on_asset(path)
      if asset = @environment.load(locate(path))
        @dependency_paths.merge(asset.metadata[:dependency_paths])
      end
      nil
    end

    # `require_asset` declares `path` as a dependency of the file. The
    # dependency will be inserted before the file and will only be
    # included once.
    #
    # If ERB processing is enabled, you can use it to dynamically
    # require assets.
    #
    #     <%= require_asset "#{framework}.js" %>
    #
    def require_asset(path)
      @required << locate(path, accept: @content_type, bundle: false)
      nil
    end

    # `stub_asset` blacklists `path` from being included in the bundle.
    # `path` must be an asset which may or may not already be included
    # in the bundle.
    def stub_asset(path)
      @stubbed << @environment.locate(path, accept: @content_type, bundle: false)
      nil
    end

    # `link_asset` declares an external dependency on an asset without directly
    # including it. The target asset is returned from this function making it
    # easy to construct a link to it.
    #
    # Returns an Asset or nil.
    def link_asset(path)
      if asset = @environment.load(locate(path))
        @dependency_paths.merge(asset.metadata[:dependency_paths])
        @links << asset.uri
      end
      asset
    end

    # Returns a Base64-encoded `data:` URI with the contents of the
    # asset at the specified path, and marks that path as a dependency
    # of the current file.
    #
    # Use `asset_data_uri` from ERB with CSS or JavaScript assets:
    #
    #     #logo { background: url(<%= asset_data_uri 'logo.png' %>) }
    #
    #     $('<img>').attr('src', '<%= asset_data_uri 'avatar.jpg' %>')
    #
    def asset_data_uri(path)
      depend_on_asset(path)
      asset = environment.find_asset(path, accept_encoding: 'base64')
      "data:#{asset.content_type};base64,#{Rack::Utils.escape(asset.to_s)}"
    end

    # Expands logical path to full url to asset.
    #
    # NOTE: This helper is currently not implemented and should be
    # customized by the application. Though, in the future, some
    # basics implemention may be provided with different methods that
    # are required to be overridden.
    def asset_path(path, options = {})
      message = <<-EOS
Custom asset_path helper is not implemented

Extend your environment context with a custom method.

    environment.context_class.class_eval do
      def asset_path(path, options = {})
      end
    end
      EOS
      raise NotImplementedError, message
    end

    # Expand logical image asset path.
    def image_path(path)
      asset_path(path, type: :image)
    end

    # Expand logical video asset path.
    def video_path(path)
      asset_path(path, type: :video)
    end

    # Expand logical audio asset path.
    def audio_path(path)
      asset_path(path, type: :audio)
    end

    # Expand logical font asset path.
    def font_path(path)
      asset_path(path, type: :font)
    end

    # Expand logical javascript asset path.
    def javascript_path(path)
      asset_path(path, type: :javascript)
    end

    # Expand logical stylesheet asset path.
    def stylesheet_path(path)
      asset_path(path, type: :stylesheet)
    end
  end
end
