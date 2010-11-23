module Sprockets
  class Error       < StandardError; end
  class FileNotFound        < Error; end
  class ContentTypeMismatch < Error; end
end
