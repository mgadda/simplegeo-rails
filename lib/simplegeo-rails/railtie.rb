require 'rails'

module SimpleGeo
  module Rails
    class Railtie < ::Rails::Railtie
      config.simplegeo = ActiveSupport::OrderedOptions.new
      
      initializer "simplegeo.set_configs" do |app|
        SimpleGeo::Client.set_credentials(app.config.simplegeo.oauth_key, app.config.simplegeo.oauth_secret)
      end
    end
  end
end