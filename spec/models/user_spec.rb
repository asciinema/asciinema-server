require 'spec_helper'

describe User do

  let(:user) { FactoryGirl.build(:user) }

  it "has valid factory" do
    FactoryGirl.build(:user).should be_valid
  end

  describe "validation" do
    let(:user) { FactoryGirl.create(:user) }

    it "validates nickname uniqueness" do
      new_user = FactoryGirl.build(:user)
      new_user.nickname = user.nickname

      new_user.should_not be_valid
      new_user.should have(1).error_on(:nickname)
    end
  end

  describe ".create_with_omniauth" do
    let(:uid)      { "123" }
    let(:provider) { "twitter" }
    let(:nickname) { "foo" }
    let(:name)     { "Foo Bar" }

    let(:auth) do
      {
        "provider" => provider,
        "uid" => uid,
        "info" => {
          "name" => name,
          "nickname" => nickname }
      }
    end

    context "valid data" do
      let(:user) { User.create_with_omniauth(auth) }

      it "creates user with valid attributes" do
        user.persisted?.should be_true

        user.provider.should == provider
        user.uid.should == uid
        user.nickname.should == nickname
        user.name.should == name
        user.avatar_url.should be_nil
      end

    end

    context "when avatar available" do
      let(:avatar_url) { "http://foo.bar/avatar.jpg" }

      before do
        OauthHelper.stub(:get_avatar_url).and_return(avatar_url)
      end

      it "assigns avatar_url" do
        user = User.create_with_omniauth(auth)
        user.avatar_url.should == avatar_url
      end
    end

    context "when nickname is taken" do
      let!(:user) { FactoryGirl.create(:user) }
      let(:nickname) { user.nickname }

      it "doesn't create user" do
        user = User.create_with_omniauth(auth)
        user.persisted?.should be_false
        user.valid?.should be_false
      end

    end
  end

  describe '#add_user_token' do
    before { user.save }

    context "when user doesn't have given token" do
      let(:token) { FactoryGirl.attributes_for(:user_token)[:token] }

      it 'returns created UserToken' do
        ut = user.add_user_token(token)
        ut.should be_kind_of(UserToken)
        ut.id.should_not be(nil)
      end
    end

    context "when user doesn't have given token" do
      let(:existing_token) { FactoryGirl.create(:user_token, :user => user) }
      let(:token) { existing_token.token }

      it 'returns existing UserToken' do
        ut = user.add_user_token(token)
        ut.should == existing_token
      end
    end
  end
end
