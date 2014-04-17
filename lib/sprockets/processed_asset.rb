require 'sprockets/asset'
require 'set'

module Sprockets
  class ProcessedAsset < Asset
    def initialize(environment, logical_path, filename)
      super

      start_time = Time.now.to_f

      encoding = environment.encoding_for_mime_type(content_type)
      data     = PathUtils.read_unicode_file(filename, encoding)

      result = environment.process(
        environment.attributes_for(filename).processors,
        filename,
        data
      )
      @source = result[:data]
      @length = source.bytesize
      @digest = environment.digest.update(source).hexdigest

      @required_paths   = result[:required_paths] + [filename]
      @stubbed_paths    = result[:stubbed_paths]
      @dependency_paths = result[:dependency_paths]

      @dependency_digest = environment.dependencies_hexdigest(@dependency_paths)
      @mtime = @dependency_paths.map { |path| environment.stat(path).mtime }.max.to_i

      elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      environment.logger.debug "Compiled #{logical_path}  (#{elapsed_time}ms)  (pid #{Process.pid})"
    end

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super
      @source         = coder['source']
      @required_paths = coder['required_paths']
      @stubbed_paths  = coder['stubbed_paths']
    end

    # Serialize custom attributes in `BundledAsset`.
    def encode_with(coder)
      super
      coder['source']         = source
      coder['required_paths'] = required_paths
      coder['stubbed_paths']  = stubbed_paths
    end
  end
end
