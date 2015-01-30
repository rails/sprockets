module Sprockets
  class SourceMapProcessor
    def self.call(input)
      case input[:content_type]
      when "application/js-sourcemap+json"
        accept = "application/javascript"
      when "application/css-sourcemap+json"
        accept = "text/css"
      else
        fail input[:content_type]
      end

      uri, _ = input[:environment].resolve!(input[:filename], accept: accept)
      asset = input[:environment].load(uri)

      JSON.generate({
        "version" => 3,
        "file" => asset.logical_path,
        "mappings" => ";#{asset.bytesize}"
      })
    end
  end
end
