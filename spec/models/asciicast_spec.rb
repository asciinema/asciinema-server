require 'spec_helper'

describe Asciicast do
  it "has valid factory" do
    Factory.build(:asciicast).should be_valid
  end

  describe '#save' do
    let(:asciicast) { Factory.build(:asciicast, :user => user) }

    context 'when no user given' do
      let(:user) { nil }

      it 'calls #assign_user' do
        asciicast.should_receive(:assign_user)
        asciicast.save
      end
    end

    context 'when user given' do
      let(:user) { Factory.build(:user) }

      it "doesn't call #assign_user" do
        asciicast.should_not_receive(:assign_user)
        asciicast.save
      end
    end
  end

  describe '#assign_user' do
    let(:user) { Factory(:user) }
    let(:asciicast) { Factory(:asciicast, :user => nil, :user_token => user_token) }

    context 'when user exists with given token' do
      let(:user_token) { Factory(:user_token, :user => user).token }

      it 'assigns user and resets user_token' do
        asciicast.assign_user
        asciicast.user.should == user
        asciicast.user_token.should be(nil)
      end
    end

    context 'when there is no user with given token' do
      let(:user_token) { 'some-foo-bar' }

      it 'assigns user' do
        asciicast.assign_user
        asciicast.user.should be(nil)
      end
    end
  end
end
