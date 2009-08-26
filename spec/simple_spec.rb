require 'spec/spec_helper'

class Family
  attr_accessor :name

  def initialize
    @kids = make_kids
  end

  def make_kids
    k1 = Kid.new
    k1.name = "Keith"

    k2 = Kid.new
    k2.name = "Josh"

    @kids = [k1, k2]
  end

  def kids
    @kids
  end
end

class Kid
  attr_accessor :name
end

def family_yaml
  # DIFFERENT KID NAMES
  "--- !ruby/object:Family \nkids: \n- " +
  "!ruby/object:Kid \n  name: Beef\n- " +
  "!ruby/object:Kid \n  name: OshGosh\n" + 
  "name: McSpadden\n"
end

describe "a simple present class with nested classes" do
  it "should use the yaml attributes over the derived object attributes" do
    yml = YAML.load(family_yaml)
    yml.kids.first.name.should == "Beef"
  end
end