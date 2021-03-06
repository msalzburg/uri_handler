require 'net/http'
require 'net/https'
require 'uri'

module URIHandler
  class Base
    
    # doc http://www.ruby-doc.org/stdlib/libdoc/uri/rdoc/
        
    # @return [Integer] The valid character length of the URI.
    attr_reader :valid_length
    # @return [Array] of valid hosts
    attr_reader :valid_hosts
    # @return [Integer] number of redirect steps SmartURI should follow.
    attr_reader :redirect_limit
    # @return [Array] of SmartResponse instances
    attr_reader :redirect_log
    # @return [String] The source uri which was passed to initialize
    attr_reader :source_uri
    # @return [Array] of valid schemes symbols e.g. :ftp, :http
    attr_reader :valid_schemes
    # @return [URI::InvalidURIError] if URI could not be parsed
    attr_reader :invalid_uri_error
    # @return [Exception] if there was some error fetching the URI
    attr_reader :fetch_error
    # @return [Array] of valid status codes
    attr_reader :valid_status
    
    # @param [String] uri the URI as string format
    # @param [Hash] options the options to create a SmartURI objects
    # @option options [String] :host
    # @option options [String] :scheme
    def initialize(uri = '', options = {})
      
      @source_uri = uri
      
      unless @source_uri.empty?
        
        @status       = nil
        @redirect_log = Array.new
                
        # handle defaults and options
        @redirect_limit = options[:redirect_limit]  || 10.to_i
        @valid_hosts    = Array(options[:host])
        @valid_length   = options[:length]          || 255.to_i
        @valid_schemes  = Array(options[:scheme])
        @valid_schemes  = [:ftp, :http, :https] if @valid_schemes.empty?
        @valid_status   = Array(options[:status])
        @valid_status   = ["200"] if @valid_status.empty?
        
        begin
          # TODO: catch URI::InvalidURIError - e.g. empty string or broken
          @uri_obj  = URI.parse(@source_uri)
          @host     = @uri_obj.host
          @scheme   = @uri_obj.scheme.nil? ? nil : @uri_obj.scheme.to_sym
        
          begin
            response  = fetch_uri(@source_uri, @redirect_limit)
            @status   = response.code
          rescue Exception => fe
            @fetch_error = fe
          end
        rescue URI::InvalidURIError => e
          @invalid_uri_error = e
        end
        
      else
        # FIXME: handle missing uri_str
      end
    end
    
    # Determines if URI has redirects.
    # @return [Boolean] if URI was redirected while resolving.
    def redirected?
      raise @invalid_uri_error if invalid_uri_error?
      raise @fetch_error if fetch_error?
      @redirect_log.size > 1
    end
    
    # Determines the URI HTTP status code
    # @return [String] with status code e.g. "200" or empty string. 
    def status
      raise @invalid_uri_error if invalid_uri_error?
      raise @fetch_error if fetch_error
      @status || String.new
    end
    
    # Determines the final URI.
    # @return [String] representation of the final URI - after redirect resolvement
    def uri
      raise @fetch_error if fetch_error
      raise @invalid_uri_error if invalid_uri_error?
      return @redirect_log.last.uri unless @redirect_log.empty?
      return @source_uri
    end
    
    # @return [String] representation of URIs host
    def host
      raise @invalid_uri_error if invalid_uri_error? 
      @host
    end
    
    # @return [Symbol] representation of URIs scheme
    def scheme
      raise @invalid_uri_error if invalid_uri_error?
      @scheme
    end
    
    # Determines the final URI.
    # @return [String] returns a String representation of the uri
    def url
      uri
    end
    
    # Validates URI on base of all validation cases.
    # @return [Boolean] if URI is valid
    def is_valid?
      valid_resolved? && valid_status?
    end
    
    def valid_resolved?
      original_is_valid? && @fetch_error.nil? && !@redirect_log.empty?
    end
    
    # Whether the original URI is valid
    def original_is_valid?
      valid_host? && valid_length? && valid_scheme?
    end
    
    def fetch_error?
      !@fetch_error.nil?
    end
    
    def invalid_uri_error?
      !@invalid_uri_error.nil?
    end
    
    # Validates the URI host and tries to match wildcard hosts.
    # @return [Boolean] if URI host ist valid
    def valid_host?
      return false if invalid_uri_error?
                  
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
      !invalid_uri_error? && (@source_uri.length <= @valid_length)
    end
    
    # Validates the URI scheme.
    # @return [Boolean] if URI scheme is valid.
    def valid_scheme?
      !invalid_uri_error? && (@valid_schemes.include?(@scheme))
    end
    
    def valid_status?
      !invalid_uri_error? &&(@valid_status.include?(@status))
    end
    
    private
    
    # Resolves an URI, follows redirects and fetches the HTTP response.
    # @param [String]  the URI as String format
    # @param [Integer] how many redirects to follow (max.)
    # @param [Hash]    (option :previous_uri is used internally to handle relative redirects)
    # @return [Net::HTTPResponse] the final HTTP response
    def fetch_uri(uri_as_string, limit, options = {})
      raise @invalid_uri_error if invalid_uri_error?
      
      uri = URI.parse(uri_as_string)
      # handle relative URLs
      if (uri.instance_of?(URI::Generic)) && options[:previous_uri]
        previous_uri      = options[:previous_uri]
        new_uri_as_string = "#{previous_uri.scheme}://#{previous_uri.host}"
        unless (previous_uri.port == 80 && previous_uri.scheme == 'http') ||
           (previous_uri.port == 443 && previous_uri.scheme == 'https')
          new_uri_as_string += ":#{previous_uri.port}"
        end
        if uri_as_string.strip =~ /^\//
          # given path is relative to root => just append
          uri_as_string = new_uri_as_string + uri_as_string.strip
        elsif previous_uri.path.strip =~ /^(.+\/)[^\/]*$/   
          # given path is relative to previous directory => remove last part from previous path
          path = $1
          path = $1 if path =~ /^(.*)(\?.*)$/ # -> remove query string
          uri_as_string = new_uri_as_string + path + uri_as_string.strip
        else
          # this should not happen => in case it does, leave URI as it was before
        end
        uri  = URI.parse(uri_as_string)
      end
      
      # get HTTP / HTTPS response
      if uri.scheme == 'https'
        http             = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        path             = uri.path.strip.empty? ? '/' : uri.path
        response         = http.request(Net::HTTP::Get.new(path))
      else
        response         = Net::HTTP.get_response(uri)
      end
      @redirect_log.push(Response.new(uri_as_string, response.code))
      
      # handle redirects
      if limit > 1 && response.is_a?(Net::HTTPRedirection)
        response  = fetch_uri(response['location'], limit - 1, {:previous_uri => uri})
      end
      return response
    end
    
  end
end
