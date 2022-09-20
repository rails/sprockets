# frozen_string_literal: true
require 'securerandom'
require 'logger'

module Sprockets
  # Public: Manifest utilities.
  module ManifestUtils
    extend self

    MANIFEST_RE = /^\.sprockets-manifest-[0-9a-f]{32}.json$/

    # Public: Find or pick a new manifest filename for target build directory.
    #
    # dirname - String dirname
    #
    # Examples
    #
    #     find_directory_manifest("/app/public/assets")
    #     # => "/app/public/assets/.sprockets-manifest-abc123.json"
    #
    # Returns String filename or nil if it cannot find one.
    def find_directory_manifest(dirname, logger = Logger.new($stderr))
      entries = File.directory?(dirname) ? Dir.entries(dirname) : []
      manifest_entries = entries.select { |e| e =~ MANIFEST_RE }
      if manifest_entries.length > 1
        manifest_entries.sort!
        logger.warn("Found multiple manifests: #{manifest_entries}. Choosing the first alphabetically: #{manifest_entries.first}")
      end
      entry = manifest_entries.first
      return nil if entry.nil?
      File.join(dirname, entry)
    end
  end
end
