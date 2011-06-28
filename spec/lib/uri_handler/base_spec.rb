require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module URIHandler
  describe Base do
    
    it "should be able to handle incorrect URIs" do
      uri = Base.new("http://wrong:uri")
      uri.is_valid?.should == false
      uri.invalid_uri_error.should_not == nil
      uri.invalid_uri_error?.should == true
      uri.fetch_error.should == nil    
      uri.fetch_error?.should == false  
      uri.valid_host?.should == false
      uri.valid_length?.should == false
      uri.valid_scheme?.should == false
      uri.valid_resolved?.should == false
      lambda {uri.status()}.should raise_error(URI::InvalidURIError)
      lambda {uri.uri()}.should raise_error(URI::InvalidURIError)
      lambda {uri.url()}.should raise_error(URI::InvalidURIError)
      lambda {uri.host()}.should raise_error(URI::InvalidURIError)
      lambda {uri.scheme()}.should raise_error(URI::InvalidURIError)
      lambda {uri.redirected?}.should raise_error(URI::InvalidURIError)
    end
    
    it "should be able to handle problems fetching URLs" do
      uri = Base.new("http://www.heise.de:8889/")
      uri.is_valid?.should == false
      uri.invalid_uri_error.should == nil
      uri.invalid_uri_error?.should == false
      uri.fetch_error.should_not == nil
      uri.fetch_error?.should == true  
      lambda {uri.redirected?()}.should raise_error
      uri.valid_host?.should == true
      uri.valid_length?.should == true
      uri.valid_scheme?.should == true
      uri.valid_resolved?.should == false
      lambda {uri.status()}.should raise_error
      lambda {uri.uri()}.should raise_error
      lambda {uri.url()}.should raise_error
      uri.host.should == "www.heise.de"
      uri.scheme.should == :http
    end
 
    context "status codes" do
      
      it "should determine the current HTTP status code" do
        uri = Base.new("https://github.com")
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
        subject.uri.should == "https://github.com/"
      end
      
      it "should handle relative redirects" do
        uri = Base.new("/relative/url/must/not/be/first", :redirect_limit => 25)
        uri.valid_status?.should be_false
        
        uri = Base.new("http://www.google.com/url?sa=X&q=http://friendfeed.com/rooms/gn-internet/de6341a4/klarmobil-umts-stick-zehn-euro-billiger&ct=ga&cad=:s7:f1:v1:d2:i1:lt:e0:p0:t1288793626:&cd=BEQB9Pbm4Y0&usg=AFQjCNEoKoDwJyNxUpwZwdU3OgNLDyrzGw", :redirect_limit => 25)
        uri.redirected?.should be_true
        uri.uri.should == "http://friendfeed.com/gn-internet/de6341a4/klarmobil-umts-stick-zehn-euro-billiger"
        uri.valid_status?.should be_true
      end
      
      it "should keep a protocol of redirects" do
        subject.redirect_log.size > 3
        subject.redirect_log[0].uri.should == "http://bit.ly/cUpI7Q"
        subject.redirect_log[1].uri.should == "http://www.github.com"
        subject.redirect_log[2].uri.should == "http://github.com/"
        subject.redirect_log[3].uri.should == "https://github.com/"
      end
      
      it "should resolve those nasty google alert redirects" do
        uri = Base.new("http://www.google.com/url?sa=X&#38;q=http://uk.shopping.com/o2-usb-e169-modem/products&#38;ct=ga&#38;cad=:s7:f1:v1:d2:i1:lt:e0:p0:t1282160966:&#38;cd=0U4pTbhMdSQ&#38;usg=AFQjCNHZL2qSnFcw7GGVZZ2x-OoZhc3lzA", :redirect_limit => 25)
        uri.valid_status?.should be_false
        
        uri = Base.new("http://www.google.com/url?sa=X&q=http://www.biosphaeren.de/forum/viewtopic.php%3Fp%3D71653&ct=ga&cad=:s7:f1:v1:d2:i1:lt:e0:p0:t1283202926:&cd=tp4b7JGWfTY&usg=AFQjCNG5zc_di8Lw6ssNKEf7bxgklIBQow", :redirect_limit => 25)
        uri.redirected?.should be_true
        uri.uri.should =~ /\Ahttp:\/\/www.biosphaeren.de\/forum\/login.php\?redirect=viewtopic\.php&p=71653&sid=[0-9a-f]{32}\Z/
        uri.valid_status?.should be_true
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
