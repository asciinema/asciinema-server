require 'spec_helper'

describe Comment do

  it "factory should be valid" do
    expect(FactoryGirl.build(:comment)).to be_valid
  end

end
