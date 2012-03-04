require 'spec_helper'

describe UserToken do
  it "has valid factory" do
    Factory.build(:user_token).should be_valid
  end
end
