require 'spec_helper'

describe UserToken do
  it "has valid factory" do
    expect(build(:user_token)).to be_valid
  end
end
