require 'spec_helper'

describe ApiToken do
  it "has valid factory" do
    expect(build(:api_token)).to be_valid
  end
end
