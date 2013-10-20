require 'spec_helper'

describe User do

  describe "validation" do
    let(:user) { create(:user) }

    it "validates nickname uniqueness" do
      new_user = build(:user)
      new_user.nickname = user.nickname

      new_user.should_not be_valid
      new_user.should have(1).error_on(:nickname)
    end
  end

  describe '#add_user_token' do
    let(:user) { build(:user) }

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
