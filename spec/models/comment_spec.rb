require 'spec_helper'

describe Comment do

  it "factory should be valid" do
    expect(build(:comment)).to be_valid
  end

end
