module Sprockets
  module Mime
    MIME_TYPES = {
      ".css"       => "text/css",
      ".eot"       => "application/vnd.ms-fontobject",
      ".erb"       => "application/x-html+ruby",
      ".gif"       => "image/gif",
      ".gz"        => "application/x-gzip",
      ".htm"       => "text/html",
      ".html"      => "text/html",
      ".jpeg"      => "image/jpeg",
      ".jpg"       => "image/jpeg",
      ".js"        => "application/javascript",
      ".json"      => "application/json",
      ".png"       => "image/png",
      ".rb"        => "application/x-ruby",
      ".svg"       => "image/svg+xml",
      ".tar"       => "application/x-tar",
      ".text"      => "text/plain",
      ".tif"       => "image/tiff",
      ".tiff"      => "image/tiff",
      ".ttf"       => "application/x-font-ttf",
      ".txt"       => "text/plain",
      ".woff"      => "application/x-font-woff",
      ".yaml"      => "text/yaml",
      ".yml"       => "text/yaml",
      ".zip"       => "application/zip"
    }

    # Returns a `Hash` of mime types registered on the environment and those
    # part of `Rack::Mime`.
    attr_reader :mime_types

    # Register a new mime type.
    def register_mime_type(mime_type, ext)
      ext = Sprockets::Utils.normalize_extension(ext)
      @mime_types[ext] = mime_type
    end

    # Returns the correct encoding for a given mime type, while falling
    # back on the default external encoding, if it exists.
    def encoding_for_mime_type(type)
      encoding = ::Encoding::BINARY if type =~ %r{^(image|audio|video)/}
      encoding ||= Sprockets.default_external_encoding
      encoding
    end

    def matches_content_type?(mime_type, path)
      # TODO: Disallow nil mime type
      mime_type.nil? ||
        mime_type == "*/*" ||
        # TODO: Review performance
        mime_type == mime_types[parse_path_extnames(path)[1]]
    end
  end
end
