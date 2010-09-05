require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module URIHandler
  describe Advanced do
    
    let (:handler) { Advanced.new }
    
    context "init" do
      
      it "should support an empty initalize" do
        handler.resolve
        handler.source.should be_nil
        handler.target.should be_nil
        handler.is_redirected?.should be_false
      end
      
      it "should handle a source and build an uri" do
        handler.source = "http://github.com"
        handler.source.is_a?(URI).should be_true
        handler.source.uri.should == "http://github.com"
      end
        
    end
    
    context "options" do        
      
      it "should handle option :auto_resolve" do
        handler.source = "http://github.com"
        handler.is_resolved?.should be_false
        
        auto_handler = Advanced.new(:source => "http://github.com", :auto_resolve => true)
        auto_handler.is_resolved?.should be_true
        
        auto_handler = Advanced.new(:auto_resolve => true)
        auto_handler.source = "http://github.com"
        auto_handler.is_resolved?.should be_true
      end
      
      it "should handle option :length" do
        handler.options[:length].should == 255

        long_handler = Advanced.new(:length => 500)
        long_handler.options[:length].should == 500        
        long_handler.source = "http://#{"o" * 523}.com"
        long_handler.steps.size.should == 0
      end
      
      it "should handle option :limit" do
        handler.options[:limit].should == 25
        
        major_handler = Advanced.new(:limit => 99)
        major_handler.options[:limit].should == 99
      end
      
      it "should handle option :source" do
        source_handler = Advanced.new(:source => "http://github.com")
        source_handler.source.uri.should == "http://github.com"
        source_handler.resolve
        source_handler.is_resolved?.should be_true
      end
      
      it "should handle option :target" do
        target_handler = Advanced.new({:source => "http://www.github.com", :target => "http://github.com/"})
        target_handler.target.uri.should == "http://github.com/"        
        target_handler.is_cached?.should be_true
        target_handler.is_resolved?.should be_false
        target_handler.is_redirected?.should be_false
      end
      
    end
    
    context "exceptions" do
      
      it "should be able to handle incorrect URIs" do
        handler.is_valid?.should be_false
        handler.source = "http://wrong:uri"
        handler.is_valid?.should be_false
      end
      
      it "should be able to handle problems fetching URLs" do
        handler.is_valid?.should be_false
        handler.source = "http://www.heise.de:8889/"
        handler.resolve
        handler.is_valid?.should == false
      end
      
    end
    
    context "redirects" do
            
      it "should resolve an uri" do
        handler.source = "http://www.github.com"
        handler.resolve
        handler.steps.size.should > 1
      end
      
      it "should notice redirection" do
        handler.source = "http://www.github.com"
        handler.is_redirected?.should be_false
        handler.resolve
        handler.is_redirected?.should be_true
      end
      
      it "should keep a protocol of redirects" do
        bitly_handler = Advanced.new
        bitly_handler.source = "http://bit.ly/cUpI7Q"
        bitly_handler.resolve
        bitly_handler.is_redirected?.should be_true
        
        bitly_handler.steps[0].uri.should == "http://bit.ly/cUpI7Q"
        bitly_handler.steps[1].uri.should == "http://www.github.com"
        bitly_handler.steps[2].uri.should == "http://github.com/" # trailing "/" only appears on resolved uri        
      end
      
      it "should resolve those nasty google alert redirects" do        
        handler.source = "http://www.google.com/url?sa=X&q=http://www.biosphaeren.de/forum/viewtopic.php%3Fp%3D71653&ct=ga&cad=:s7:f1:v1:d2:i1:lt:e0:p0:t1283202926:&cd=tp4b7JGWfTY&usg=AFQjCNG5zc_di8Lw6ssNKEf7bxgklIBQow"
        handler.resolve
        handler.is_redirected?.should be_true
        handler.target.uri.should == "http://www.biosphaeren.de/forum/viewtopic.php?p=71653"
      end
      
    end
    
  end
end
