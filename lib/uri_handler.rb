require 'active_record'
require File.dirname(__FILE__) + '/uri_handler/base'
require File.dirname(__FILE__) + '/uri_handler/advanced'

# = URIHandler
# The URIHandler module is included into ActiveRecord::Base and
# == Setup
# @example Simple Integration
#   class Foo < ActiveRecord::Base
#     has_uri_handler :url
#   end
# @example Integration with options
#   class Foo < ActiveRecord::Base
#     has_uri_handler :url, {
#       :auto_resolve => true,
#       :limit => 99
#     }
#   end
# @since 0.1.0
module URIHandler

  # Extends the including object with the URIHandler::ClassMethods module.
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
    
    # Creates a method for the given name and maps an URIHandler object to it.
    # @param [Symbol] name The name for the virtual attribute
    # @param [Hash] opts The options to initalize the URIHandler see URIHandler::Advanced#initalize
    def acts_as_uri(name, opts = {})
      send :include, InstanceMethods
      
      # Define uri_handler_options hash and store specific configuration
      write_inheritable_attribute(:uri_handler_options, {}) if uri_handler_options.nil?
      uri_handler_options[name] = opts

      # Define accessor method for specific URIHandler
      define_method("#{name}") { uri_handler_for(name) }

      before_save :save_uri_handler
    end
    
    # Returns the uri_handler_options
    # @return [Hash] The class global options hash
    def uri_handler_options
      read_inheritable_attribute(:uri_handler_options)
    end      
  end
  
  module InstanceMethods    
    def uri_handler_for(name)
      
      # handle options
      options = self.class.uri_handler_options[name]
      
      source  = self.send "#{name}_source".to_sym if respond_to? "#{name}_source".to_sym
      options.merge!({:source => source}) unless source.blank?
      
      target  = self.send "#{name}_target".to_sym if respond_to? "#{name}_target".to_sym
      options.merge!({:target => target}) unless target.blank?
      
      @_uri_handler ||= {}
      @_uri_handler[name] ||= Advanced.new(options)
    end
    
    def save_uri_handler
      @_uri_handler.each_pair do |name, value|
        send("#{name}_source=", value.source.uri) if respond_to? "#{name}_source".to_sym
        send("#{name}_target=", value.target.uri) if respond_to? "#{name}_target".to_sym
      end
    end        
  end
  
end

ActiveRecord::Base.send :include, URIHandler