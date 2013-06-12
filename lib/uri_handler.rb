unless defined?(URIHandler::VERSION)
  require File.join(File.dirname(__FILE__), 'uri_handler/version.rb')
end

require File.dirname(__FILE__) + '/uri_handler/response'
require File.dirname(__FILE__) + '/uri_handler/base'

require 'active_record'

module URIHandler

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def acts_as_uri(uri_field, options = {})

      #field_mapping = options.delete(:map_to)

      cattr_accessor :uri_handler_field
      cattr_accessor :uri_handler_options
      cattr_accessor :uri_handler_uri_field

      self.uri_handler_uri_field = uri_field
      self.uri_handler_options   = options
      #self.uri_handler_field     = (field_mapping || :uri_handler).to_s

      send :include, InstanceMethods
    end
  end

  module InstanceMethods
    def build_uri(options = {})
      return "tatata"
      #options.merge(read_attribute(self.class.uri_handler_options))
      #return(URIHandler::Base.new(read_attribute(self.class.uri_handler_uri_field), options))
    end
  end

end

ActiveRecord::Base.send :include, URIHandler