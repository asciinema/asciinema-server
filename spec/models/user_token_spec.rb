require 'spec_helper'

describe UserToken do
  it "has valid factory" do
    FactoryGirl.build(:user_token).should be_valid
  end
end
