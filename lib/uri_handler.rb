require 'active_record'
require File.dirname(__FILE__) + '/uri_handler/base'
require File.dirname(__FILE__) + '/uri_handler/advanced'

module URIHandler
  
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
    def acts_as_uri(name, opts = {})
      send :include, InstanceMethods
      
      write_inheritable_attribute(:uri_handler_options, {}) if uri_handler_options.nil?
      uri_handler_options[name] = opts
      
      define_method("#{name}") do
        uri_handler_for(name)
      end      
    end
    
    # Returns the uri_handler_options
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
      
      @_uri_handler_options ||= {}
      @_uri_handler_options[name] ||= Advanced.new(options)
    end        
  end
  
end

ActiveRecord::Base.send :include, URIHandler