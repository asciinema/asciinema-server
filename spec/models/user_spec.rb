require 'spec_helper'

describe User do

  let(:user) { Factory.build(:user) }

  it "has valid factory" do
    Factory.build(:user).valid?.should be_true
  end

  describe ".create_with_omniauth" do
    let(:uid)      { "123" }
    let(:provider) { "twitter" }
    let(:name)     { "foo" }

    let(:auth) do
      {
        "provider" => provider,
        "uid" => uid,
        "info" => {
          "name" => name }
      }
    end

    it "should create user with valid attributes" do
      user = User.create_with_omniauth(auth)
      user.provider.should == provider
      user.uid.should == uid
      user.name.should == name
    end

  end
end
