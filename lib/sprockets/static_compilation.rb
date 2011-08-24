require 'sprockets/static_asset'

require 'fileutils'
require 'pathname'

module Sprockets
  # `Caching` is an internal mixin whose public methods are exposed on
  # the `Environment` and `Index` classes.
  module StaticCompilation
    # `static_root` is a special path where compiled assets are served
    # from. This is usually set to a `/public` or `/static` directory.
    #
    # In a production environment, Apache or nginx should be
    # configured to serve assets from the directory.
    def static_root
      @static_root ||= nil
    end

    # Assign a static root directory.
    def static_root=(root)
      expire_index!
      logger.warn "Sprockets::Environment#static_root is deprecated\n#{caller[0..2].join("\n")}"
      @static_root = root ? Pathname.new(root) : nil
    end

    # `precompile` takes a like of paths, globs, or `Regexp`s to
    # compile into `static_root`.
    #
    #     precompile "application.js", "*.css", /.+\.(png|jpg)/
    #
    # This usually ran via a rake task.
    def precompile(*paths)
      options = paths.last.is_a?(Hash) ? paths.pop : {}

      logger.warn "Sprockets::Environment#precompile is deprecated\n#{caller[0..2].join("\n")}"

      if options[:to]
        target = options[:to]
      elsif static_root
        warn "Sprockets::Environment#static_root is deprecated"
        target = static_root
      else
        raise ArgumentError, "missing target"
      end

      target = Pathname.new(target)

      manifest = {}
      paths.each do |path|
        each_logical_path do |logical_path|
          if path.is_a?(Regexp)
            # Match path against `Regexp`
            next unless path.match(logical_path)
          else
            # Otherwise use fnmatch glob syntax
            next unless File.fnmatch(path.to_s, logical_path)
          end

          if asset = find_asset(logical_path)
            manifest[logical_path] = asset.digest_path

            filename = target.join(asset.digest_path)

            # Ensure directory exists
            FileUtils.mkdir_p filename.dirname

            # Write file
            asset.write_to(filename)

            # Write compressed file if its a bundled asset like .js or .css
            asset.write_to("#{filename}.gz") if asset.is_a?(BundledAsset)
          end
        end
      end
      manifest
    end
  end
end
