require 'spec_helper'

describe Comment do

  it "factory should be valid" do
    FactoryGirl.build(:comment).should be_valid
  end

end
