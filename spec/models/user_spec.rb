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

end
