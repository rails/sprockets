module Sprockets
  class SourceMapCommentProcessor
    def self.call(input)
      case input[:content_type]
      when "application/javascript"
        extname = ".js"
        comment = "\n//# sourceMappingURL=%s"
      when "text/css"
        extname = ".css"
        comment = "\n/*# sourceMappingURL=%s */"
      else
        fail input[:content_type]
      end

      env = input[:environment]

      uri, _ = env.resolve!(input[:filename], accept: input[:content_type])
      asset = env.load(uri)

      url = "#{input[:name]}#{extname}.map"
      asset.metadata.merge(data: asset.source + (comment % url))
    end
  end
end
