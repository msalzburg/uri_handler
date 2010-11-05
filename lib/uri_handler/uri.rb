module URIHandler
  module CoreExtensions
    module URIGeneric
      
      # Extends the URI:Generic class to handle its own Net::HTTPResponse object.
      class URI::Generic
    
        alias_method :uri, :to_s
    
        # Checks wether the object has a response object.
        # @return [Boolean] if the response is nil or not.
        def is_resolved?
          !@response.nil?
        end
    
        # Returns the response object.
        # @return [Net:HTTPResponse | nil] the stored response
        def response
          return @response ||= nil
        end
    
        # Takes and stores a Net:HTTPResponse object as response.
        # @param [Net::HTTPResponse]
        def response=(response = nil)
          @response = response if response.is_a?(Net::HTTPResponse)
        end
    
      end
      
    end
  end
end