module Sprockets
  module HTTPUtils
    extend self

    # Internal: Test mime type against mime range.
    #
    #    match_mime_type?('text/html', 'text/*') => true
    #    match_mime_type?('text/plain', '*') => true
    #    match_mime_type?('text/html', 'application/json') => false
    #
    # Returns true if the given value is a mime match for the given mime match
    # specification, false otherwise.
    def match_mime_type?(value, matcher)
      v1, v2 = value.split('/', 2)
      m1, m2 = matcher.split('/', 2)
      (m1 == '*' || v1 == m1) && (m2.nil? || m2 == '*' || m2 == v2)
    end

    # Internal: Parse Accept header quality values.
    #
    # Adapted from Rack::Utils#q_values.
    #
    # Returns an Array of [String, Float].
    def parse_q_values(values)
      values.to_s.split(/\s*,\s*/).map do |part|
        value, parameters = part.split(/\s*;\s*/, 2)
        quality = 1.0
        if md = /\Aq=([\d.]+)/.match(parameters)
          quality = md[1].to_f
        end
        [value, quality]
      end
    end

    # Internal: Find the best qvalue match from an Array of available options.
    #
    # Adapted from Rack::Utils#q_values.
    #
    # Returns the matched String from available Array.
    def find_best_q_match(q_value_header, available, &matcher)
      matcher ||= lambda { |a, b| a == b }

      matches = []

      parse_q_values(q_value_header).each do |accepted, quality|
        if match = available.find { |option| matcher.call(option, accepted) }
          matches << [match, quality]
        end
      end

      if matches.any?
        matches.sort_by { |match, quality| -quality }.first.first
      end
    end
  end
end
