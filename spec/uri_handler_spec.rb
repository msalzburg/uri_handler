require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Foo < ActiveRecord::Base
  attr_accessor :url
  attr_accessor :url_2
  
  acts_as_uri   :url, {:host => "github.com"}
  
  def initialize
    @url = "http://github.com"
  end
end

describe "URIHandler" do
  it "should integrate via a activerecord acts_as_uri class method" do
    test = Foo.new
    test.build_uri.should == "tatata"
    pending
    #test_handler = test.build_uri(:length => 300)
    #test_handler.valid_length.should == 300
    #test_handler.is_a?(URIHandler::Base).should be_true
  end
  
  it "should be able to suppot multiple uris in one activerecord model"  
end
