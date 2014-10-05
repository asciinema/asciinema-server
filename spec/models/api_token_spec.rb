require 'rails_helper'

describe ApiToken do

  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:token) }

  describe "uniqueness validation" do
    before do
      create(:api_token)
    end

    it { should validate_uniqueness_of(:token) }
  end

  describe '.for_token' do
    subject { described_class.for_token(token) }

    context "when ApiToken with given token exists" do
      let(:token) { attributes_for(:api_token)[:token] }
      let!(:api_token) { create(:api_token, token: token) }

      it { should eq(api_token) }
    end

    context "when ApiToken with given token doesn't exist" do
      let(:token) { 'no-no' }

      it { should be(nil) }
    end
  end

  describe '#reassign_to' do
    subject { api_token.reassign_to(target_user) }

    let(:api_token) { described_class.new }
    let(:user) { User.new }
    let(:target_user) { User.new }

    before do
      api_token.user = user
      allow(user).to receive(:merge_to)
    end

    context "when source user is a dummy user" do
      before do
        allow(user).to receive(:confirmed?) { false }
      end

      it "merges user to target user" do
        subject
        expect(user).to have_received(:merge_to).with(target_user)
      end
    end

    context "when target user is the same user" do
      let(:target_user) { user }

      it "doesn't do anything" do
        subject
        expect(user).to_not have_received(:merge_to)
      end
    end

    context "when source user is confirmed user" do
      before do
        allow(user).to receive(:confirmed?) { true }
      end

      it "raises ApiTokenTakenError" do
        expect { subject }.to raise_error(ApiToken::ApiTokenTakenError)
      end
    end
  end

end
