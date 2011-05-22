module Sprockets
  class Engine < ::Rails::Engine
    initializer "sprockets.notifier" do
      Sprockets::Notifier.notify(Rails.logger)
    end
  end
end
