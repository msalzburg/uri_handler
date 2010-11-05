require 'net/http'
require 'uri'
require File.dirname(__FILE__) + '/uri'

module URIHandler
  # the base functionality
  # @since 0.1.0
  class Advanced

    attr_reader :options
    attr_reader :steps

    # @param [Hash] opts the option hash
    # @option opts [Boolean]  :auto_resolve defines if source should be resolved
    # @option opts [Integer]  :length defines the maximum character count for uris
    # @option opts [Integer]  :limit defines the recursion level to follow redirects
    # @option opts [String]   :source the source uri to initialize source
    # @option opts [String]   :target the target uri to initialize cached_target
    def initialize(opts = {})
      reset_handler
      @options  = default_options.merge(opts)
      
      self.source = @options[:source] unless @options[:source].nil?
      load_cached_target(@options[:target]) unless @options[:target].nil?
    end
    
    # get the source uri object
    # @return [URI::Generic] the source uri object
    def source
      return @steps.first unless @steps.empty?
      return nil
    end
    
    # Sets a new source uri string and resolves it in case of :auto_resolve => true
    # @param [String] The new uri
    # @return [Boolean] The success status
    def source=(new_uri)
      reset_handler
      result = add_step(new_uri)
      resolve if options[:auto_resolve]
      return result
    end
    
    
    def resolve
      unless @steps.empty?
        @cached_target = nil
       begin
          fetch_uri(@options[:limit].to_i)
        rescue Exception => e
          @resolve_error = e
        end
      end
    end
    
    def target
      return @cached_target if is_cached?
      return @steps.last    unless @steps.empty?
      return nil
    end
    
    def is_redirected?
      return @steps.size > 1
    end
    
    def is_cached?
      !@cached_target.nil?
    end
    
    def is_resolved?
      return @steps.last.is_resolved? unless @steps.empty?
      return false
    end
    
    def is_valid?
      is_resolved? && @invalid_uri_error.nil? && @resolve_error.nil?
    end
    
    private
    
    def default_options
      return {
        :auto_resolve => false,
        :length       => 255,
        :limit        => 25,
        :source       => nil
      }
    end
    
    def reset_handler
      @invalid_uri_error  = nil
      @resolve_error      = nil
      @cached_target      = nil
      @steps              = Array.new
    end
    
    def load_cached_target(new_uri)
      begin
        @cached_target = URI.parse(new_uri) if new_uri.size <= @options[:length].to_i
      rescue URI::InvalidURIError => e
        @invalid_uri_error = e
      end      
    end
    
    def add_step(new_uri)
      valid_uri = (new_uri.size <= @options[:length].to_i)
      begin
        if valid_uri
          tmp_uri = URI.parse(new_uri)
          tmp_uri.extend URIHandler::CoreExtensions::URIGeneric
          @steps << tmp_uri
        end
      rescue URI::InvalidURIError => e
        @invalid_uri_error = e
        valid_uri = false
      end
      return valid_uri
    end
            
    # Resolves an URI, follows redirects and fetches the HTTP response.
    # @param [Integer] limit for uri recursion
    def fetch_uri(limit)
      raise @invalid_uri_error if @invalid_uri_error
      @steps.last.response = Net::HTTP.get_response(@steps.last)
      
      if limit > 0 && @steps.last.response.is_a?(Net::HTTPRedirection)
        fetch_uri(limit - 1) if add_step(@steps.last.response['location'])  
      end
    end
    
  end
end