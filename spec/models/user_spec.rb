require 'spec_helper'

describe User do

  let(:user) { Factory.build(:user) }

  it "has valid factory" do
    Factory.build(:user).should be_valid
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

    it "creates user with valid attributes" do
      user = User.create_with_omniauth(auth)
      user.provider.should == provider
      user.uid.should == uid
      user.name.should == name
      user.avatar_url.should be_nil
    end

    context "when avatar available" do
      let(:avatar_url) { "http://foo.bar/avatar.jpg"}

      before do
        OauthHelper.stub(:get_avatar_url).and_return(avatar_url)
      end

      it "assigns avatar_url" do
        user = User.create_with_omniauth(auth)
        user.avatar_url.should == avatar_url
      end

    end
  end
end
