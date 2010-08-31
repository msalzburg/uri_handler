module URIHandler
  class Response

    # @return [String]
    attr_reader :uri
    # @return [String]
    attr_reader :code
    
    # @param [String] a string representation of an URI.
    # @param [String] a string representation of the HTTP status code
    def initialize(uri = String, code = String)
      @uri  = uri
      @code = code
    end
  end
end