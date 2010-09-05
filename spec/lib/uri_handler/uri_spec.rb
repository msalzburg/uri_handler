require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe URI do
  let(:uri_generic) { URI.parse("http://github.com") }
  
  it "should respond to uri alias method" do
    uri_generic.to_s.should == "http://github.com"
    uri_generic.uri.should == "http://github.com"
  end
  
  it "should handle a Net:HTTPResponse object" do
    uri_generic.is_resolved?.should be_false
    uri_generic.response = Net::HTTP.get_response(uri_generic)
    uri_generic.is_resolved?.should be_true
    uri_generic.response.code.should == "200"
  end
  
end