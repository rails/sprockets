require 'sprockets'

module Rails
  def self.default_sprockets_paths
    ["app/assets",
     "app/javascripts",
     "vendor/sprockets/*/src",
     "vendor/sprockets/*/lib",
     "vendor/plugins/*/assets",
     "vendor/plugins/*/javascripts",
     "vendor/plugins/*/app/assets",
     "vendor/plugins/*/app/javascripts"]
  end

  def self.assets
    @assets ||= begin
      env = Sprockets::Environment.new(self.root.to_s)
      env.logger = self.logger
      env.ensure_fresh_assets = !ActionController::Base.perform_caching

      self.default_sprockets_paths.each do |pattern|
        Dir[pattern].each do |dir|
          env.paths << dir
        end
      end

      env
    end
  end
end
