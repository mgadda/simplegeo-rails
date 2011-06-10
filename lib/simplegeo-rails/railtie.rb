require 'rails'

module SimpleGeo
  module Rails
    class Railtie < ::Rails::Railtie
      config.simplegeo = ActiveSupport::OrderedOptions.new
      
      initializer "simplegeo.set_configs" do |app|
        SimpleGeo::Client.set_credentials(app.config.simplegeo.oauth_key, app.config.simplegeo.oauth_secret)
        SimpleGeo::Rails::Place.sg_private = app.config.simplegeo.sg_private || false
      end
    end
  end
end