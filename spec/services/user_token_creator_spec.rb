require 'spec_helper'

describe UserTokenCreator do

  let(:user_token_creator) { described_class.new }

  describe '#create' do
    let(:user) { create(:user) }
    let(:token) { 'a-toh-can' }
    let(:user_token) { double('user_token', token: token,
                                            persisted?: persisted) }

    subject { user_token_creator.create(user, token) }

    before do
      allow(user).to receive(:add_user_token) { user_token }
    end

    context "when token was persisted" do
      let(:persisted) { true }
      let!(:asciicast_1) { create(:asciicast, :user => nil,
                                              :user_token => token) }
      let!(:asciicast_2) { create(:asciicast, :user => nil,
                                              :user_token => 'please') }
      let!(:asciicast_3) { create(:asciicast, :user => create(:user),
                                              :user_token => 'nonono') }

      it { should be(1) }

      it 'assigns the user to all asciicasts with given token' do
        subject

        asciicast_1.reload; asciicast_2.reload; asciicast_3.reload

        expect(asciicast_1.user).to eq(user)
        expect(asciicast_2.user).not_to eq(user)
        expect(asciicast_3.user).not_to eq(user)
      end

      it 'resets the token on all asciicasts with given token' do
        subject

        asciicast_1.reload; asciicast_2.reload; asciicast_3.reload

        expect(asciicast_1.user_token).to be(nil)
        expect(asciicast_2.user_token).not_to be(nil)
        expect(asciicast_3.user_token).not_to be(nil)
      end
    end

    context "when token wasn't persisted " do
      let(:persisted) { false }

      it { should be(nil) }
    end
  end

end
