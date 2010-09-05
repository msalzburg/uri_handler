module URIHandler
  
  class URI::Generic
    
    alias_method :uri, :to_s
    
    def is_resolved?
      !response.nil?
    end
    
    def response
      return @response ||= nil
    end
    
    def response=(response)
      @response = response if response.is_a?(Net::HTTPResponse)
    end
    
  end
  
end