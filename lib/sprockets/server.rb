require 'time'

module Sprockets
  # A Rack asset server
  #
  #   require 'sprockets'
  #
  #   map '/sprocket.js' do
  #     run Sprockets::Server.new(
  #       :root => "app/javascripts",
  #       :source_files => "app/javascripts/**/*.js"
  #     )
  #   end
  class Server
    def initialize(options = {})
      @secretary = Secretary.new(options)
    end

    def source
      concatenation.to_s
    end

    def md5
      concatenation.md5
    end

    def last_modified
      @secretary.source_last_modified
    end

    def etag
      %("#{md5}")
    end

    YEAR_IN_SECONDS = 31540000

    def call(env)
      headers = {}

      headers["Cache-Control"] = "public, must-revalidate"

      if env["QUERY_STRING"] == self.md5
        headers["Cache-Control"] << ", max-age=#{YEAR_IN_SECONDS}"
      end

      headers["ETag"] = self.etag
      headers["Last-Modified"] = self.last_modified.httpdate

      if etag = env["HTTP_IF_NONE_MATCH"]
        return [304, headers, []] if etag == headers["ETag"]
      end

      if time = env["HTTP_IF_MODIFIED_SINCE"]
        return [304, headers, []] if time == headers["Last-Modified"]
      end

      body = source
      headers.merge!({
        "Content-Type" => "text/javascript",
        "Content-Length" => body.size.to_s
      })
      [200, headers, env["REQUEST_METHOD"] == "HEAD" ? [] : [body]]
    end

    private
      def concatenation
        @secretary.reset! unless source_is_unchanged?
        @secretary.concatenation
      end

      def source_is_unchanged?
        previous_last_modified, @last_modified = @last_modified,
          @secretary.source_last_modified
        previous_last_modified == @last_modified
      end
  end
end
