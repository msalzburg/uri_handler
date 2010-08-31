require 'net/http'
require 'uri'

module URIHandler
  class Base
    
    # doc http://www.ruby-doc.org/stdlib/libdoc/uri/rdoc/
    
    # @return [String] representation of URIs host
    attr_reader :host
    # @return [Integer] The valid character length of the URI.
    attr_reader :valid_length
    # @return [Array] of valid hosts
    attr_reader :valid_hosts
    # @return [Integer] number of redirect steps SmartURI should follow.
    attr_reader :redirect_limit
    # @return [Array] of SmartResponse instances
    attr_reader :redirect_log
    # @return [Symbol] representation of URIs scheme
    attr_reader :scheme
    # @return [String] The source uri which was passed to initialize
    attr_reader :source_uri
    # @return [Array] of valid schemes symbols e.g. :ftp, :http
    attr_reader :valid_schemes
    
    # @param [String] uri the URI as string format
    # @param [Hash] options the options to create a SmartURI objects
    # @option options [String] :host
    # @option options [String] :scheme
    def initialize(uri = String, options = {})
      
      @source_uri = uri
      
      unless @source_uri.empty?
        
        @status       = nil
        @redirect_log = Array.new
                
        # handle defaults and options
        @redirect_limit = options[:redirect_limit]  || 10.to_i
        @valid_hosts    = options[:host].to_a       || Array.new
        @valid_length   = options[:length]          || 255.to_i
        @valid_schemes  = Array(options[:scheme])   || [:ftp, :http]
        
        begin
          # TODO: catch URI::InvalidURIError - e.g. empty string or broken
          @uri_obj  = URI.parse(@source_uri)
          @host     = @uri_obj.host
          @scheme   = @uri_obj.scheme.to_sym
        
          begin
            response  = fetch_uri(@source_uri, @redirect_limit)
            @status   = response.code
          rescue
            # FIXME: handle errors
          end
        rescue
        end
        
      else
        # FIXME: handle missing uri_str
      end
    end
    
    # Determines if URI has redirects.
    # @return [Boolean] if URI was redirected while resolving.
    def redirected?
      @redirect_log.size > 1
    end
    
    # Determines the URI HTTP status code
    # @return [String] with status code e.g. "200" or empty string. 
    def status
      @status || String.new
    end
    
    # Determines the final URI.
    # @return [String] representation of the final URI - after redirect resolvement
    def uri
      return @redirect_log.last.uri unless @redirect_log.empty?
      return @source_uri
    end
    
    # Determines the original URI.
    # @return [String] returns a String representation of the uri
    def url
      uri
    end
    
    # Validates URI on base of all validation cases.
    # @return [Boolean] if URI is valid
    def is_valid?
      valid_host? && valid_length? && valid_scheme?
    end
    
    # Validates the URI host and tries to match wildcard hosts.
    # @return [Boolean] if URI host ist valid
    def valid_host?
                  
      # check for wildcard definition e.g. *.github.com
      wildcard_hosts = Array.new
      @valid_hosts.each do |valid_host|
        result = valid_host.scan(/^\*\.(.*\..*)$/)
        wildcard_hosts << result[0] unless result.empty?
      end
      return wildcard_hosts.include?(@host.scan(/^(?:.*\.)?(.*\..*)$/)[0]) unless wildcard_hosts.empty?
      
      # basic check
      return @valid_hosts.include?(@host) || @valid_hosts.empty?            
    end
    
    # Validates the URI length.
    # @return [Boolean] True if the URI length is below the length option.
    def valid_length?
      "#{uri}".size <= @valid_length
    end
    
    # Validates the URI scheme.
    # @return [Boolean] if URI scheme is valid.
    def valid_scheme?
      @valid_schemes.include?(@scheme)
    end
    
    private
    
    # Resolves an URI, follows redirects and fetches the HTTP response.
    # @param [String] the URI as String format
    # @return [Net::HTTPResponse] the final HTTP response
    def fetch_uri(uri, limit)
      response  = Net::HTTP.get_response(URI.parse(uri))
      @redirect_log.push(Response.new(uri, response.code))
      
      if limit > 1 && response.is_a?(Net::HTTPRedirection)
        response  = fetch_uri(response['location'], limit - 1)
      end
      return response
    end
    
  end
end