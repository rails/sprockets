module Sprockets
  # For JS developers who are colonfobic, concatenating JS files using
  # the module pattern usually leads to syntax errors.
  #
  # The `SafetyColons` processor will insert missing semicolons to the
  # end of the file.
  #
  # This behavior can be disabled with:
  #
  #     environment.unregister_postprocessor 'application/javascript', Sprockets::SafetyColons
  #
  class SafetyColons
    def self.call(input)
      new.call(input)
    end

    def call(input)
      data = input[:data]
      missing_semicolon?(data) ? "#{data};\n" : data
    end

    private
      def missing_semicolon?(data)
        i = data.size - 1
        while i >= 0
          c = data[i]
          i -= 1
          if c == "\n" || c == " " || c == "\t"
            next
          elsif c != ";"
            return true
          else
            return false
          end
        end
        false
      end
  end
end
