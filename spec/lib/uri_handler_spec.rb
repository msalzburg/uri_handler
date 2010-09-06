require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Tableless < ActiveRecord::Base
  def self.columns
    @columns ||= [];
  end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default,
    sql_type.to_s, null)
  end

  # Override the save method to prevent exceptions.
  def save(validate = true)
    validate ? valid? : true
  end
end

class Foo < Tableless
  column :link_source, :string
  column :link_target, :string
  
  acts_as_uri(:url, {
    :source => "http://www.github.com",
    :auto_resolve => true
  })
  
  acts_as_uri :link
end

describe "URIHandler" do
  it "should integrate via a activerecord acts_as_uri class method" do
    test = Foo.new
    test.url.source.uri.should == "http://www.github.com"
    test.url.is_resolved?.should be_true
    test.url.target.uri.should == "http://github.com/"
  end
  
  it "should be available as activerecord attribute" do
    test = Foo.new
    test.url.source = "http://github.com"
    test.url.is_resolved?.should be_true
    test.url.is_redirected?.should be_false
  end
  
  it "should initalize on base of activerecord attributes" do
    test = Foo.new({:link_source => "http://github.com", :link_target => "http://github.com/"})
    test.link.is_resolved?.should be_false
    test.link.target.uri.should == "http://github.com/"
    test.link.is_redirected?.should be_false
  end
  
  it "should be able to suppot multiple uris in one activerecord model" do
    test = Foo.new({:link_source => "http://github.com", :link_target => "http://github.com/"})
    
    test.url.target.uri.should  == "http://github.com/"
    test.link.target.uri.should == "http://github.com/"
    test.url.target.should != test.link.target 
  end
  
  it "should save the uri_handler before activerecord save" do
    test = Foo.new
    test.link_source = "test"
    test.link.source = "http://www.github.com"
    test.link.resolve
    test.save_uri_handler
    test.link.is_resolved?.should be_true
    test.link_source.should == "http://www.github.com"
    test.link.target.uri.should == "http://github.com/"
    test.link_target.should == "http://github.com/"
  end
end
