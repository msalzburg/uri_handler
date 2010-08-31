require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module URIHandler
  
  describe Response do
    
    it "should store the request uri and the reponse code" do
      response = Response.new("http://www.github.com", "200")
      response.uri.should == "http://www.github.com"
      response.code.should == "200"
    end
    
  end
  
end