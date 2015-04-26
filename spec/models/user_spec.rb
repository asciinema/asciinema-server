require 'rails_helper'

describe User do

  it 'gets an auth_token upon creation' do
    attrs = attributes_for(:user)
    attrs.delete(:auth_token)
    user = described_class.create!(attrs)

    expect(user.auth_token).to be_kind_of(String)
  end

  describe "#valid?" do
    let!(:existing_user) { create(:user, username: 'the-user-name') }
    let(:user) { described_class.new }

    context "when username is set" do
      it { should allow_value('sickill').for(:username) }
      it { should allow_value('sick-ill').for(:username) }
      it { should allow_value('ab').for(:username) }
      it { should allow_value('s' * 16).for(:username) }
      it { should allow_value('Sickill').for(:username) }
      it { should_not allow_value('sick.ill').for(:username) }
      it { should_not allow_value('-sickill').for(:username) }
      it { should_not allow_value('sickill-').for(:username) }
      it { should_not allow_value('a').for(:username) }
      it { should_not allow_value('s' * 17).for(:username) }
    end
  end

  describe '.generate_auth_token' do
    it 'generates a string token' do
      token = described_class.generate_auth_token

      expect(token).to be_kind_of(String)
    end

    it 'generates unique token' do
      token_1 = described_class.generate_auth_token
      token_2 = described_class.generate_auth_token

      expect(token_1).to_not eq(token_2)
    end
  end

  describe '.for_api_token' do
    subject { described_class.for_api_token(token) }

    let(:token) { 'f33e6188-f53c-11e2-abf4-84a6c827e88b' }

    context "when token exists" do
      let!(:existing_token) { create(:api_token, token: token) }

      it { should eq(existing_token.user) }
    end

    context "when token doesn't exist" do
      it { should be(nil) }
    end
  end

  describe '.for_auth_token' do
    subject { described_class.for_auth_token(auth_token) }

    context "when user with given token exists" do
      let(:auth_token) { user.auth_token }
      let(:user) { create(:user) }

      it { should eq(user) }
    end

    context "when user with given token doesn't exist" do
      let(:auth_token) { 'Km3u8ZsAZ_Qo0qgBT0rE0g' }

      it { should be(nil) }
    end
  end

  describe '#username=' do
    it 'strips the whitespace' do
      user = described_class.new(username: ' sickill ')

      expect(user.username).to eq('sickill')
    end
  end

  describe '#email=' do
    it 'strips the whitespace' do
      user = described_class.new(email: ' foo@bar.com ')

      expect(user.email).to eq('foo@bar.com')
    end
  end

  describe '#theme' do
    it 'returns proper theme when theme_name is not blank' do
      user = described_class.new(theme_name: 'tango')

      expect(user.theme.name).to eq('tango')
    end

    it 'returns nil when theme_name is blank' do
      user = described_class.new(theme_name: '')

      expect(user.theme).to be(nil)
    end
  end

  describe '#assign_api_token' do
    subject { user.assign_api_token(token) }

    let(:user) { create(:user) }
    let(:token) { 'a33e6188-f53c-11e2-abf4-84a6c827e88b' }

    before do
      allow(ApiToken).to receive(:for_token).with(token) { api_token }
    end

    context "when given token doesn't exist" do
      let(:api_token) { nil }

      it { should be_kind_of(ApiToken) }
      it { should be_persisted }
      specify { expect(subject.token).to eq(token) }
    end

    context "when given token already exists" do
      let(:api_token) { double('api_token', reassign_to: nil) }

      it "reassigns it to the user" do
        subject
        expect(api_token).to have_received(:reassign_to).with(user)
      end

      it { should be(api_token) }
    end
  end

  describe '#asciicast_count' do
    subject { user.asciicast_count }

    let(:user) { create(:user) }

    before do
      2.times { create(:asciicast, user: user) }
    end

    it { should eq(2) }
  end

  describe '#other_asciicasts' do
    subject { user.other_asciicasts(asciicast, 1) }

    let(:user) { create(:user) }
    let(:asciicast) { create(:asciicast, user: user) }

    it "returns other asciicasts by user excluding the given one" do
      other = create(:asciicast, user: user)
      expect(subject).to eq([other])
    end
  end

  describe '#merge_to' do
    subject { user.merge_to(target_user) }

    let(:user) { create(:user) }
    let(:target_user) { create(:user) }
    let!(:api_token_1) { create(:api_token, user: user) }
    let!(:api_token_2) { create(:api_token, user: user) }
    let!(:asciicast_1) { create(:asciicast, user: user) }
    let!(:asciicast_2) { create(:asciicast, user: user) }
    let(:updated_at) { 1.hour.from_now }

    before do
      Timecop.freeze(updated_at) do
        subject
      end
    end

    it "reassigns all user api tokens to the target user" do
      api_token_1.reload
      api_token_2.reload

      expect(api_token_1.user).to eq(target_user)
      expect(api_token_2.user).to eq(target_user)
      expect(api_token_1.updated_at.to_i).to eq(updated_at.to_i)
      expect(api_token_2.updated_at.to_i).to eq(updated_at.to_i)
    end

    it "reassigns all user asciicasts to the target user" do
      asciicast_1.reload
      asciicast_2.reload

      expect(asciicast_1.user).to eq(target_user)
      expect(asciicast_2.user).to eq(target_user)
      expect(asciicast_1.updated_at.to_i).to eq(updated_at.to_i)
      expect(asciicast_2.updated_at.to_i).to eq(updated_at.to_i)
    end

    it "removes the source user" do
      expect(user).to be_destroyed
    end
  end
end
