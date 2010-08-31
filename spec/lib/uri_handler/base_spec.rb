require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module URIHandler
  describe Base do
    
    it "should be able to handle incorrect URIs" do
      uri = Base.new("http://wrong:uri")
      uri.is_valid?.should == false
      uri.invalid_uri_error.should_not == nil
      uri.redirected?.should == false
      uri.valid_host?.should == false
      uri.valid_length?.should == false
      uri.valid_scheme?.should == false
      lambda {uri.status()}.should raise_error #(URI::InvalidURIError)
      lambda {uri.uri()}.should raise_error #(URI::InvalidURIError)
    end
  
    context "status codes" do
      
      it "should determine the current HTTP status code" do
        uri = Base.new("http://github.com")
        uri.status.should == "200"
        
        uri = Base.new("http://bit.ly/cUpI7Q", :redirect_limit => 1)
        uri.status.should == "301"
        
        # TODO: add further checks 
                
        uri = Base.new("http://www.github.com/what-going-on-over-here")
        uri.status.should == "404"
      end
      
    end
    
    context "virtual attributes" do
      it "should handle uri and url as alias" do
        uri = Base.new("http://github.com")
        uri.url.should == uri.uri
      end
    end
    
    context "redirects" do
      # redirect chain: http://bit.ly/cUpI7Q -> http://www.github.com -> http://github.com/
      subject{ Base.new("http://bit.ly/cUpI7Q") }
      
      it "should follow up redirects and determine redirect uri" do
        subject.redirected?.should be_true
        subject.uri.should == "http://github.com/"
      end
      
      it "should keep a protocol of redirects" do
        subject.redirect_log.size > 2
        subject.redirect_log[0].uri.should == "http://bit.ly/cUpI7Q"
        subject.redirect_log[1].uri.should == "http://www.github.com"
        subject.redirect_log[2].uri.should == "http://github.com/" # trailing "/" only appears on resolved uri
      end      
    end

    context "options and validations" do  
          
      it "should handle a passed scheme option" do
        uri = Base.new("http://www.github.com", :scheme => :http)
        uri.scheme.should == :http
        uri.valid_scheme?.should be_true
        
        uri = Base.new("ftp://www.github.com", :scheme => :http)
        uri.scheme.should == :ftp
        uri.valid_scheme?.should == false
        
        uri = Base.new("ftp://www.github.com", :scheme => [:http, :ftp])
        uri.scheme.should == :ftp
        uri.valid_scheme?.should == true
      end
      
      it "should handle a passed host option" do
        uri = Base.new("http://www.github.com", :host => "www.github.com")
        uri.host.should == "www.github.com"
        uri.valid_host?.should == true
        
        uri = Base.new("http://www.github.com", :host => "www.37signals.com")
        uri.host.should == "www.github.com"
        uri.valid_host?.should == false
        
        uri = Base.new("http://www.github.com", :host => ["www.37signals.com", "www.github.com"])
        uri.host.should == "www.github.com"
        uri.valid_host?.should == true
      end
      
      it "should extract only the host information from passed host option" do
        pending
        uri = Base.new("http://www.github.com", :host => "http://www.github.com/rails")
        uri.valid_hosts.include?("www.github.com").should == true
      end
      
      it "should handle toplevel hosts with wildcard subdomains" do
        uri = Base.new("http://www.github.com", :host => ["www.37signals.com", "*.github.com"])
        uri.host.should == "www.github.com"
        uri.valid_host?.should == true
        
        uri = Base.new("http://www.github.com", :host => ["*.37signals.com", "github.com"])
        uri.host.should == "www.github.com"
        uri.valid_host?.should == false
      end
      
      it "should handle a passed redirect_limit option" do
        uri = Base.new("http://www.github.com", :redirect_limit => 23)
        uri.redirect_limit.should == 23
      end
      
      it "should handle a passed length option" do
        uri = Base.new("http://www.github.com", :length => 300)
        uri.valid_length.should == 300
        
        uri = Base.new("http://www.github.com", :length => 255)
        uri.valid_length.should == 255
      end
      
      it "should validate uri length" do
        uri = Base.new("http://www.#{"o" * 240}.com")
        uri.valid_length?.should == true

        uri = Base.new("http://www.#{"o" * 300}.com")
        uri.valid_length?.should == false

        uri = Base.new("http://www.github.com")
        uri.valid_length?.should == true
      end
      
      it "should handle a passed status code option" do
        uri = Base.new("http://www.github.com", :status => "200")
        uri.status.should == "200"
        uri.valid_status.include?("200").should be_true
        uri.valid_status?.should be_true
        
        uri = Base.new("http://bit.ly/cUpI7Q", :status => "200", :redirect_limit => 0)
        uri.status.should == "301"
        uri.valid_status.include?("301").should be_false
        uri.valid_status?.should be_false
        
        uri = Base.new("http://bit.ly/cUpI7Q", :status => "301", :redirect_limit => 0)
        uri.status.should == "301"
        uri.valid_status.include?("301").should be_true
        uri.valid_status?.should be_true
      end
       
    end
    
  end
end
