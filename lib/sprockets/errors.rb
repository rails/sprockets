# Define some basic Sprockets error classes
module Sprockets
  class Error           < StandardError; end
  class ArgumentError           < Error; end
  class ContentTypeMismatch     < Error; end
  class EncodingError           < Error; end
  class FileNotFound            < Error; end
  class FileOutsidePaths        < Error; end
  class NotImplementedError     < Error; end
end
