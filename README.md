Usage
=====

This gem consists of one class: SimpleGeo::Rails::Place. Its called Place because the term Feature doesn't exactly make me think of a place. Hopefully others agree.

In your development.rb, staging.rb, production.rb, etc, add the following:

    app.config.simplegeo.oauth_key = 'your_oauth_key'
    app.config.simplegeo.oauth_key = 'your_oauth_secret'

    
Finding Places
--------------

    Place.find('<simplegeo feature id>')

raises ActiveRecord::RecordNotFound if feature is not found

    Place.find_by_id('<simplegeo feature id>')

returns nil if feature is not found
  
    Place.find_by_lat_and_long(35, -105)
    Place.find_by_address('1 Broadway, Boulder, CO')

The last two methods return nil or array of Place instances

ActiveModel Compliant(ish)
---------------------

Place implements most of ActiveModel and as such responds to most methods you would expect to find on your ActiveRecord instances.

    place = SimpleGeo::Rails::Place.new(:name => 'Sketchy Hamburger Joint', :lat => 35, :long => -105)
    place.as_json
     => {"place"=>{"name"=>"Sketchy Hamburger Joint", "lat"=>35, "long"=>-105}}

    place.name = 'Gourmet Hamburgers'
     => "Gourmet Hamburgers" 
    
    place.name_was
     => "Sketchy Hamburger Joint" 
    
    place.name_changed?
     => true 


Place is respond_with() compatible

    class YourController < ActionController::Base
      respond_to(:json)
      
      def index
        respond_with(@places = SimpleGeo::Rails::Place.find_by_lat_and_long(35, -105, :category => 'Fast Food'))
      end
    end

Creating Places
---------------

    place = SimpleGeo::Rails::Place.new(:name => 'Sketchy Hamburger Joint', :lat => 35, :long => -105)
    place.save # or place.save!

Destroying Places
-----------------

    place = SimpleGeo::Rails::Place.find('<some id>')
    place.delete
  
  