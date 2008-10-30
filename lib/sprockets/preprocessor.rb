module Sprockets
  class Preprocessor
    attr_reader :environment, :output_file, :source_files
    
    def initialize(environment, options = {})
      @environment = environment
      @output_file = OutputFile.new
      @source_files = []
      @options = options
    end
    
    def require(source_file)
      return if source_files.include?(source_file)
      source_files << source_file
      
      source_file.each_source_line do |source_line|
        if source_line.require?
          require_from_source_line(source_line)
        else
          record_source_line(source_line)
        end
      end
    end
    
    protected
      attr_reader :options
    
      def require_from_source_line(source_line)
        require pathname_from(source_line).source_file
      end
      
      def record_source_line(source_line)
        skip_pdoc_comments(source_line) do
          unless source_line.comment? && strip_comments?
            output_file.record(source_line)
          end
        end
      end

      def skip_pdoc_comments(source_line)
        yield unless strip_comments?

        @commented ||= false

        if source_line.begins_multiline_comment?
          @commented = true
        end

        yield unless @commented

        if source_line.closes_multiline_comment?
          @commented = false
        end
      end

      def strip_comments?
        options[:strip_comments] != false
      end
      
      def pathname_from(source_line)
        pathname = send(pathname_finder_from(source_line), source_line)
        raise_load_error_for(source_line) unless pathname
        pathname
      end

      def pathname_for_require_from(source_line)
        environment.find(location_from(source_line))
      end
      
      def pathname_for_relative_require_from(source_line)
        source_line.source_file.find(location_from(source_line))
      end

      def pathname_finder_from(source_line)
        "pathname_for_#{kind_of_require_from(source_line)}_from"
      end

      def kind_of_require_from(source_line)
        source_line.require[/^(.)/, 1] == '"' ? :relative_require : :require
      end

      def location_from(source_line)
        location = source_line.require[/^.(.*).$/, 1]
        File.join(File.dirname(location), File.basename(location, ".js") + ".js")
      end
      
      def raise_load_error_for(source_line)
        kind = kind_of_require_from(source_line).to_s.tr("_", " ")
        file = File.split(location_from(source_line)).last
        raise LoadError, "can't find file for #{kind} `#{file}' (#{source_line.inspect})"
      end
  end
end
