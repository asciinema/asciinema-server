require 'spec_helper'

describe Comment do

  it "factory should be valid" do
    Factory.build(:comment).should be_valid
  end
end
