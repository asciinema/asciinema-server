require 'spec_helper'

describe ApiTokenCreator do

  let(:api_token_creator) { described_class.new(clock) }
  let(:clock) { double('clock', now: now) }
  let(:now) { Time.now }

  describe '#create' do
    let(:user) { create(:user) }
    let(:token) { 'a-toh-can' }
    let(:api_token) { double('api_token', token: token,
                                            persisted?: persisted) }

    subject { api_token_creator.create(user, token) }

    before do
      allow(user).to receive(:add_api_token) { api_token }
    end

    context "when token was persisted" do
      let(:persisted) { true }
      let(:old_updated_at) { 3.days.ago }

      let!(:asciicast_1) { create(:asciicast, :user => nil,
                                              :api_token => token,
                                              :updated_at => old_updated_at) }
      let!(:asciicast_2) { create(:asciicast, :user => nil,
                                              :api_token => 'please',
                                              :updated_at => old_updated_at) }
      let!(:asciicast_3) { create(:asciicast, :user => create(:user),
                                              :api_token => 'nonono',
                                              :updated_at => old_updated_at) }

      it { should be(1) }

      it 'assigns the user to all matching asciicasts' do
        subject

        asciicast_1.reload; asciicast_2.reload; asciicast_3.reload

        expect(asciicast_1.user).to eq(user)
        expect(asciicast_2.user).not_to eq(user)
        expect(asciicast_3.user).not_to eq(user)
      end

      it 'resets the token on all matching asciicasts' do
        subject

        asciicast_1.reload; asciicast_2.reload; asciicast_3.reload

        expect(asciicast_1.api_token).to be(nil)
        expect(asciicast_2.api_token).not_to be(nil)
        expect(asciicast_3.api_token).not_to be(nil)
      end

      it 'updates the updated_at field on all matching asciicasts' do
        subject

        asciicast_1.reload; asciicast_2.reload; asciicast_3.reload

        expect(asciicast_1.updated_at.to_i).to eq(now.to_i)
        expect(asciicast_2.updated_at.to_i).to eq(old_updated_at.to_i)
        expect(asciicast_3.updated_at.to_i).to eq(old_updated_at.to_i)
      end
    end

    context "when token wasn't persisted " do
      let(:persisted) { false }

      it { should be(nil) }
    end
  end

end
