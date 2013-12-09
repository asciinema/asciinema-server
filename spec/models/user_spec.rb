require 'spec_helper'

describe User do

  it 'gets an auth_token upon creation' do
    attrs = attributes_for(:user)
    attrs.delete(:auth_token)
    user = described_class.create!(attrs)

    expect(user.auth_token).to be_kind_of(String)
  end

  describe "#valid?" do
    before do
      create(:user)
    end

    it { should validate_uniqueness_of(:nickname) }
    it { should validate_uniqueness_of(:email) }
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

  describe '.for_credentials' do
    subject { described_class.for_credentials(credentials) }

    let!(:user) { create(:user, provider: 'twitter', uid: '1') }

    context "when there is matching record" do
      let(:credentials) { double('credentials', provider: 'twitter', uid: '1') }

      it { should eq(user) }
    end

    context "when there isn't matching record" do
      let(:credentials) { double('credentials', provider: 'twitter', uid: '2') }

      it { should be(nil) }
    end
  end

  describe '.for_email' do
    subject { described_class.for_email(email) }

    let!(:user) { create(:user, email: 'foo@bar.com') }

    context "when there is matching record" do
      let(:email) { 'foo@bar.com' }

      it { should eq(user) }
    end

    context "when there isn't matching record" do
      let(:email) { 'qux@bar.com' }

      it { should be(nil) }
    end
  end

  describe '#nickname=' do
    it 'strips the whitespace' do
      user = User.new(nickname: ' sickill ')

      expect(user.nickname).to eq('sickill')
    end
  end

  describe '#email=' do
    it 'strips the whitespace' do
      user = User.new(email: ' foo@bar.com ')

      expect(user.email).to eq('foo@bar.com')
    end
  end

  describe '#add_user_token' do
    let(:user) { build(:user) }

    before { user.save }

    context "when user doesn't have given token" do
      let(:token) { attributes_for(:user_token)[:token] }

      it 'returns created UserToken' do
        ut = user.add_user_token(token)
        expect(ut).to be_kind_of(UserToken)
        expect(ut.id).not_to be(nil)
      end
    end

    context "when user doesn't have given token" do
      let(:existing_token) { create(:user_token, :user => user) }
      let(:token) { existing_token.token }

      it 'returns existing UserToken' do
        ut = user.add_user_token(token)
        expect(ut).to eq(existing_token)
      end
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

end
