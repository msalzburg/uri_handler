require 'net/http'
require 'uri'
require File.dirname(__FILE__) + '/uri'

module URIHandler
  class Advanced

    attr_reader :options
    attr_reader :steps
    
    def initialize(opts = {})
      reset_handler
      @options  = default_options.merge(opts)
      
      self.source = @options[:source] unless @options[:source].nil?
      load_cached_target(@options[:target]) unless @options[:target].nil?
    end
    
    def source
      return @steps.first unless @steps.empty?
      return nil
    end
        
    def source=(new_uri)
      reset_handler
      result = add_step(new_uri)
      resolve if options[:auto_resolve]
      return result
    end
    
    def resolve
      unless @steps.empty?
        @last_target = nil
       begin
          fetch_uri(@options[:limit].to_i)
        rescue Exception => e
          @resolve_error = e
        end
      end
    end
    
    def target
      return @cached_target if is_cached?
      return @steps.last  unless @steps.empty?
      return nil
    end
    
    def is_redirected?
      return @steps.size > 1
    end
    
    def is_cached?
      !@cached_target.nil?
    end
    
    def is_resolved?
      @steps.last.is_resolved? unless @steps.empty?
    end
    
    def is_valid?
      self.is_resolved? && @invalid_uri_error.nil? && @resolve_error.nil?
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
        @steps << URI.parse(new_uri) if valid_uri
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