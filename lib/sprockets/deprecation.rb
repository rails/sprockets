module Sprockets
  class Deprecation

    attr_reader :callstack

    def initialize(callstack = nil)
      @callstack = callstack || caller_locations(2)
    end

    def warn(message)
      deprecation_message(message).tap do |m|
        behavior.each { |b| b.call(m, callstack) }
      end
    end

    private
      def deprecation_message(message = nil)
        message ||= "You are using deprecated behavior which will be removed from the next major or minor release."
        "DEPRECATION WARNING: #{message} #{ deprecation_caller_message }"
      end

      def deprecation_caller_message
        file, line, method = extract_callstack(callstack)
        if file
          if line && method
            "(called from #{method} at #{file}:#{line})"
          else
            "(called from #{file}:#{line})"
          end
        end
      end

      def extract_callstack
        return _extract_callstack if callstack.first.is_a? String

        offending_line = callstack.find { |frame|
          frame.absolute_path && !ignored_callstack(frame.absolute_path)
        } || callstack.first

        [offending_line.path, offending_line.lineno, offending_line.label]
      end

      def _extract_callstack
        warn "Please pass `caller_locations` to the deprecation API" if $VERBOSE
        offending_line = callstack.find { |line| !ignored_callstack(line) } || callstack.first

        if offending_line
          if md = offending_line.match(/^(.+?):(\d+)(?::in `(.*?)')?/)
            md.captures
          else
            offending_line
          end
        end
      end
  end
  private_constant :Deprecation
end
