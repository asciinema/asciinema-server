require 'spec_helper'

describe UserToken do
  it "has valid factory" do
    expect(FactoryGirl.build(:user_token)).to be_valid
  end
end
