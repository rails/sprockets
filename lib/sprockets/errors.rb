# frozen_string_literal: true
# Define some basic Sprockets error classes
module Sprockets
  class Error           < StandardError; end
  class ArgumentError           < Error; end
  class ContentTypeMismatch     < Error; end
  class NotImplementedError     < Error; end
  class NotFound                < Error; end
  class ConversionError         < NotFound; end
  class FileNotFound            < NotFound; end
  class FileOutsidePaths        < NotFound; end

  # Used to wrap non-sprockets errors
  class LoadError < NotFound
    attr_reader :cause

    def initialize(asset_name)
      message = String.new("Error finding and loading '#{asset_name}':\n")
      message << "#{$!.class}: #{$!.message}"

      super(message)
      set_backtrace($!.backtrace)
      @cause = $!
    end
  end
end
