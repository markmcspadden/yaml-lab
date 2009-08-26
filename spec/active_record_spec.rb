require 'spec/spec_helper'

require 'rubygems'
require 'active_record'

ActiveRecord::Base.logger = Logger.new("../test.log")

# Setup a db in memory
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

# Setup migrations for our example class in the db
def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :posts do |t|
      t.string :body
      t.datetime :created_at
    end
    create_table :comments do |t|
      t.string :body
      t.integer :post_id
      t.datetime :created_at
    end
  end
end
def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

# Setup the db
setup_db

# Add our example class
class Post < ActiveRecord::Base
  has_many :comments
end
class Comment < ActiveRecord::Base
  belongs_to :post
end

class TransferPost < ActiveRecord::Base
  #set_table_name :posts
end

describe "an active record class with associations" do
  before(:all) do
    @post = Post.new(:body => "This is a new post.")
    @post.save!
    
    @comment = Comment.new(:body => "This is a comment on that post.", :post => @post)
    @comment.save
  end
  
  def post_yaml
    <<-EOS
    --- !ruby/object:Post 
    attributes: 
      body: This is a new post.
      id: "1"
      created_at: 2009-08-19 11:08:24
    attributes_cache: {}

    comments: 
    - !ruby/object:Comment 
      attributes: 
        body: This is a comment on that post.
        post_id: "1"
        id: "1"
        created_at: 2009-08-19 11:08:24
      attributes_cache: {}  
    - !ruby/object:Comment 
      attributes: 
        body: This is a 2nd comment on that post.
        post_id: "1"
        id: "2"
        created_at: 2009-08-19 11:10:24
      attributes_cache: {}      
    EOS
  end 
  
  after(:all) do
    teardown_db
  end
  
  def load_yaml
    YAML.load(post_yaml)
  end  
  
  it "should load the yaml and get the post" do
    load_yaml.should == @post
  end
  it "should use the post yaml attributes instead of those in the db" do
    @post.update_attributes!(:body => "This is an old post.")
    
    load_yaml.should be_is_a(Post)
    load_yaml.body.should == "This is a new post."
  end
  it "should use the comment yaml attributes instead of those in the db" do
    pending "THIS SPEC DOES NOT WORK AND IS THE MAIN ISSUE BEHIND THIS EXERCISE"
    @comment.update_attributes!(:body => "This is NOT a comment on that post")
    
    yaml_post = load_yaml
    yaml_post.comments.first.body.should == "This is a comment on that post."
  end
  
  def parse_yaml
    YAML.parse(post_yaml)
  end
  
  it "should try get the comments on their own" do
    @comment.update_attributes!(:body => "This is NOT a comment on that post.")
    
    parse_yaml.select!("comments").first.first.body.should == "This is a comment on that post."
  end
  
  it "should get the project on its own" do
    post_from_yaml = Post.new(parse_yaml.select!("attributes").first)
    post_from_yaml.body.should == "This is a new post."
    
    post_from_yaml = parse_yaml.transform.clone
    post_from_yaml.body.should == "This is a new post."
  end
  
  it "should recreate a similar post/comments structure with different ids" do
    new_post = parse_yaml.transform.clone
    new_post.save!
    
    parse_yaml.select!("comments").first.each do |comment|
      new_post.comments << comment.clone
    end
    
    post = Post.last
    post.id.should_not == @post.id
    post.comments.size.should == 2
  end
  
end