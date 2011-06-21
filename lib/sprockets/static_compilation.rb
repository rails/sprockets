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
      @static_root
    end

    # Assign a static root directory.
    def static_root=(root)
      expire_index!
      @static_root = root ? Pathname.new(root) : nil
    end

    # `precompile` takes a like of paths, globs, or `Regexp`s to
    # compile into `static_root`.
    #
    #     precompile "application.js", "*.css", /.+\.(png|jpg)/
    #
    # This usually ran via a rake task.
    def precompile(*paths)
      raise "missing static root" unless static_root

      paths.each do |path|
        files.each do |logical_path|
          if path.is_a?(Regexp)
            # Match path against `Regexp`
            next unless path.match(logical_path.to_s)
          else
            # Otherwise use fnmatch glob syntax
            next unless logical_path.fnmatch(path.to_s)
          end

          if asset = find_asset(logical_path)
            attributes  = attributes_for(logical_path)
            digest_path = attributes.path_with_fingerprint(asset.digest)
            filename    = static_root.join(digest_path)

            # Ensure directory exists
            FileUtils.mkdir_p filename.dirname

            # Write file
            asset.write_to(filename)

            # Write compressed file if its a bundled asset like .js or .css
            asset.write_to("#{filename}.gz") if asset.is_a?(BundledAsset)
          end
        end
      end
    end

    protected
      def compute_digest
        # Add static root to environment digest
        super.update(static_root.to_s)
      end

    private
      # Get all reachable files in environment path
      def files
        files = Set.new
        paths.each do |base_path|
          base_pathname = Pathname.new(base_path)
          Dir["#{base_pathname}/**/*"].each do |filename|
            logical_path = Pathname.new(filename).relative_path_from(base_pathname)
            files << attributes_for(logical_path).without_engine_extensions
          end
        end
        files
      end
  end
end
