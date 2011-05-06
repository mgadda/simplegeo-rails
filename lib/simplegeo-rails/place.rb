module SimpleGeo
  module Rails
    class Place
            
      extend ::ActiveModel::Naming
  
      include ::ActiveModel::Validations
  
      # http://api.rubyonrails.org/classes/ActiveModel/AttributeMethods.html
      include ::ActiveModel::AttributeMethods
  
      # http://api.rubyonrails.org/classes/ActiveModel/Callbacks.html
      extend ::ActiveModel::Callbacks
  
      # http://api.rubyonrails.org/classes/ActiveModel/Conversion.html
      include ::ActiveModel::Conversion
  
      # http://api.rubyonrails.org/classes/ActiveModel/Serialization.html
      include ::ActiveModel::Serializers::JSON
  
      # http://api.rubyonrails.org/classes/ActiveModel/Dirty.html
      include ::ActiveModel::Dirty


      def initialize(attrs=nil)
        self.attributes = attrs
        @persisted = false
        @destroyed = false    
      end

      PLACE_ATTRIBUTES = [:id, :name, :url, :owner, :type, :classifier_type, :category, 
                          :subcategory, :address_attributes, :address, :phone,
                          :lat, :long, :record_id]  
  
      def attributes=(attrs)
        @attributes = HashWithIndifferentAccess.new(attrs)
        if !@attributes.has_key?(:address) || (@attributes.has_key?(:address) && !@attributes[:address].kind_of?(OpenStruct))
          if @attributes[:address].kind_of?(Hash)
            @attributes[:address] = OpenStruct.new(@attributes[:address])
          else
            @attributes[:address] = OpenStruct.new
          end
          
        end
      end
  
      def attributes
        @attributes
      end
  
      attr_accessor *PLACE_ATTRIBUTES
  
      define_attribute_methods PLACE_ATTRIBUTES
  
      PLACE_ATTRIBUTES.each do |attribute|
        define_method attribute do
          self.attributes[attribute]
        end
        define_method "#{attribute}=" do |val|
          name_will_change! unless val == self.send(attribute)
          self.attributes[attribute] = val
        end
      end
      
      def address_attributes=(attrs)
        self.address = OpenStruct.new(attrs)
      end
      
      validates_presence_of :name, :lat, :long, :type
  
      def new_record?
        !@persisted
      end
  
      def save
        valid? ? create_or_update : false
      end
  
      def save!
        valid? ? (create_or_update || raise(ActiveRecord::RecordNotSaved)) : raise(ActiveRecord::RecordInvalid.new(self))
      end
  
      def create_or_update
        result = persisted? ? update : create
        result != false
      end
     
      def persisted?
        @persisted && !destroyed?
      end
  
      def create
        create_response = SimpleGeo::Client.post(SimpleGeo::Endpoint.endpoint_url('places'), as_geojson)

        self.id = create_response['id']
        reload
    
        @persisted = true    
    
        @previously_changed = changes
        @changed_attributes.clear
        true
        
      rescue
        false
      end
  
      def update
        # should be SimpleGeo::Client.put, but simplegeo doesn't comply with Rest
        # despite what their document indicates
        SimpleGeo::Client.post(SimpleGeo::Endpoint.feature(self.id.split('@').shift), as_geojson)

        @previously_changed = changes
        @changed_attributes.clear    
        true
        
      rescue
        false
      end
  
      # Returns true if this object hasn't been saved yet -- that is, a record
      # for the object doesn't exist in the data store yet; otherwise, returns false.
      def new_record?
        !@persisted
      end

      # Returns true if this object has been destroyed, otherwise returns false.
      def destroyed?
        @destroyed
      end

      # Returns if the record is persisted, i.e. it's not a new record and it was
      # not destroyed.
      def persisted?
        @persisted && !destroyed?
      end   
  
      def reload
        @changed_attributes.clear
        self.attributes = self.class.find(self.id.split('@').shift).attributes
        self
      end
  
      def destroy
        if persisted?
          SimpleGeo::Client.delete(SimpleGeo::Endpoint.feature(self.id.split('@').shift))
        end

        @destroyed = true    
        freeze
      end
      # method to clear out nils
      # method which generates hash but includes only changed fields
      
      def serializable_hash(options=nil)
        hash = super(options)
        hash["address"] = self.address.as_json["table"]
        hash
      end
      def as_geojson
        # Generate hash for values that have changed only (even to nil or blank)
        json = {}
    
        json[:type] = type if type_changed? || new_record?
    
        if name_changed? || new_record?
          json[:properties] = {}
          json[:properties][:name] = name
        end
        if lat_changed? || long_changed? || new_record?
          json[:geometry] = {:coordinates => [long, lat]}
        end
    
        json[:id] = id.split('@').shift unless new_record?
    
        json[:properties] ||= {}
        json[:properties][:record_id] = record_id unless record_id.blank?
        
        if address.present? && (address.changed? || new_record?)
          json[:properties] ||= {}
          json[:properties][:province] = address.state if (address.state_changed? || (new_record? && address.try(:state).present?))
          json[:properties][:city] = address.city if (address.city_changed? || (new_record? && address.try(:city).present?))
          json[:properties][:country] = address.country if (address.country_changed? || (new_record? && address.try(:country).present?))
          json[:properties][:address] = address.street if (address.street_changed? || (new_record? && address.try(:street).present?))
          json[:properties][:postcode] = address.postal_code if (address.postal_code_changed? || (new_record? && address.try(:postal_code).present?))
        end
        
        json[:properties][:phone] = phone if (phone_changed? || (new_record? && phone.present?))
        json[:properties][:owner] = owner if (owner_changed? || (new_record? && owner.present?))

        if classifier_type_changed? || (new_record? && classifier_type.present?)
          json[:properties][:classifiers] = []
          json[:properties][:classifiers] << {}
          json[:properties][:classifiers].first[:type] = classifier_type
        end
    
        if category_changed? || (new_record? && category.present?)
          json[:properties][:classifiers] = []
          json[:properties][:classifiers] << {}
          json[:properties][:classifiers].first[:type] = category
        end
    
        if subcategory_changed? || (new_record? && subcategory.present?)
          json[:properties][:classifiers] = []
          json[:properties][:classifiers] << {}
          json[:properties][:classifiers].first[:type] = subcategory
        end
    
        json[:private] = true
        json
      end
  
      class << self
            
        def find(id)
          from_record(SimpleGeo::Client.get_feature(id))
        end
    
        def find_by_id(id)
          from_record(SimpleGeo::Client.get_feature(id)) rescue nil
        end
    
        def find_by_lat_and_long(lat, long, options={})            
          features = SimpleGeo::Client.get_places(lat, long, options)
          return from_geojson(features) if features[:type] == 'Feature'
      
          if features[:type] == 'FeatureCollection'
            features[:features].map do |feature|
              from_geojson(feature)
            end
          end
        # rescue
        #       nil
        end
    
        def find_by_address(address, options={})      
          features = SimpleGeo::Client.get_places_by_address(address, options)
          return from_geojson(features) if features[:type] == 'Feature'
      
          if features[:type] == 'FeatureCollection'
            places = features[:features].map do |feature|
              from_geojson(feature)
            end
          end  
      
          places
        # rescue
        #       nil
        end
        
        def create(attrs={})
          returning(Place.new(attrs)) do |place|
            place.save
          end
        end
        
        def create!(attrs={})
          returning(Place.new(attrs)) do |place|
            Place.new(attrs).save!
          end          
        end
        
        def from_record(record)
          return nil unless record.kind_of?(SimpleGeo::Record)
      
          Place.new.instance_eval do
            self.attributes['id'] = record.id
            self.record_id = record.properties[:record_id]
            self.lat = record.lat
            self.long = record.lon
            self.type = record.type || 'Feature'
            self.name = record.properties[:name]
            self.owner = record.properties[:owner]
            self.url = record.properties[:url]
            self.phone = record.properties[:phone]
        
            classifier = record.properties[:classifiers].first
            if classifier.present?
              self.classifier_type = classifier[:type]
              self.category = classifier[:category]
              self.subcategory = classifier[:type]
            end
        
            self.address = OpenStruct.new(:street => record.properties[:address],
                                       :city => record.properties[:city],
                                       :state => record.properties[:province],
                                       :country => record.properties[:country],
                                       :postal_code => record.properties[:postcode])
            @persisted = true
            self
          end
        end
    
        def from_geojson(feature)
          return nil unless feature.kind_of?(Hash)
      
          Place.new.instance_eval do
            if(feature[:geometry][:type] == 'Point') 
              self.long, self.lat = feature[:geometry][:coordinates]
            end
      
            if(feature[:type] == 'Feature') 
              self.attributes['id'] = feature[:id]
              props = feature[:properties]
        
              self.record_id = props[:record_id]
              
              # General Properties
              self.name = props[:name]
              self.url = props[:url]
              self.owner = props[:owner]
              self.phone = props[:phone]
        
              # Classifiers
              classifier = props[:classifiers].first
        
              if classifier.present?
                self.classifier_type = classifier[:type]
                self.category = classifier[:category]
                self.subcategory = classifier[:type]
              end
              
              # Address
              self.address = OpenStruct.new(:street => props[:address],
                                         :city => props[:city],
                                         :state => props[:province],
                                         :country => props[:country],
                                         :postal_code => props[:postcode], 
                                         :place_id => self.id)

              @persisted = true
              self
            end                         
          end
        end
      end
    end
  end
end