require 'spec_helper'

describe User do

  it "is not dummy by default" do
    expect(described_class.new).to_not be_dummy
  end

  it 'gets an auth_token upon creation' do
    attrs = attributes_for(:user)
    attrs.delete(:auth_token)
    user = described_class.create!(attrs)

    expect(user.auth_token).to be_kind_of(String)
  end

  describe "#valid?" do
    let!(:existing_user) { create(:user) }
    let(:user) { described_class.new }

    it { should validate_presence_of(:nickname) }

    context "when user is dummy" do
      before do
        user.dummy = true
      end

      it "doesn't check for nickname uniqueness" do
        user.nickname = existing_user.nickname
        user.valid?
        expect(user.errors[:nickname]).to be_empty
      end

      it "doesn't check for email presence" do
        user.email = nil
        user.valid?
        expect(user.errors[:email]).to be_empty
      end

      it "doesn't check for email uniqueness" do
        user.email = existing_user.email
        user.valid?
        expect(user.errors[:email]).to be_empty
      end
    end

    context "when user is real" do
      before do
        user.dummy = false
      end

      it "checks for nickname uniqueness" do
        user.nickname = existing_user.nickname
        user.valid?
        expect(user.errors[:nickname]).to_not be_empty
      end

      it "checks for email presence" do
        user.email = nil
        user.valid?
        expect(user.errors[:email]).to_not be_empty
      end

      it "checks for email uniqueness" do
        user.email = existing_user.email
        user.valid?
        expect(user.errors[:email]).to_not be_empty
      end
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

  describe '.for_api_token' do
    subject { described_class.for_api_token(token, username) }

    let(:token) { 'f33e6188-f53c-11e2-abf4-84a6c827e88b' }
    let(:username) { 'somerandomguy' }

    context "when token doesn't exist" do
      it "returns a persisted user record" do
        expect(subject.id).not_to be(nil)
      end

      it "assigns given username to the user" do
        expect(subject.nickname).to eq(username)
      end

      it "assigns given api token to the user" do
        expect(subject.api_tokens.first.token).to eq(token)
      end

      context "and username is nil" do
        let(:username) { nil }

        it "returns a persisted user record" do
          expect(subject.id).not_to be(nil)
        end

        it "assigns 'anonymous' as username to the user" do
          expect(subject.nickname).to eq('anonymous')
        end
      end

      context "and username is an empty string" do
        let(:username) { nil }

        it "returns a persisted user record" do
          expect(subject.id).not_to be(nil)
        end

        it "assigns 'anonymous' as username to the user" do
          expect(subject.nickname).to eq('anonymous')
        end
      end
    end

    context "when token already exists" do
      let!(:existing_token) { create(:api_token, token: token) }

      it "returns a persisted user record" do
        expect(subject).to eq(existing_token.user)
      end
    end

    context "when token is nil" do
      let(:token) { nil }

      it { should be(nil) }
    end

    context "when token is an empty string" do
      let(:token) { '' }

      it { should be(nil) }
    end
  end

  describe '#nickname=' do
    it 'strips the whitespace' do
      user = described_class.new(nickname: ' sickill ')

      expect(user.nickname).to eq('sickill')
    end
  end

  describe '#email=' do
    it 'strips the whitespace' do
      user = described_class.new(email: ' foo@bar.com ')

      expect(user.email).to eq('foo@bar.com')
    end
  end

  describe '#add_api_token' do
    let(:user) { build(:user) }

    before { user.save }

    context "when user doesn't have given token" do
      let(:token) { attributes_for(:api_token)[:token] }

      it 'returns created ApiToken' do
        ut = user.add_api_token(token)
        expect(ut).to be_kind_of(ApiToken)
        expect(ut.id).not_to be(nil)
      end
    end

    context "when user doesn't have given token" do
      let(:existing_token) { create(:api_token, :user => user) }
      let(:token) { existing_token.token }

      it 'returns existing ApiToken' do
        ut = user.add_api_token(token)
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

  describe '#asciicasts_excluding' do
    subject { user.asciicasts_excluding(asciicast, 1) }

    let(:user) { create(:user) }
    let(:asciicast) { create(:asciicast, user: user) }

    it "returns other asciicasts by user excluding the given one" do
      other = create(:asciicast, user: user)
      expect(subject).to eq([other])
    end
  end

  describe '#editable_by?' do
    subject { user.editable_by?(other) }

    let(:user) { create(:user) }

    context "when it's the same user" do
      let(:other) { user }

      it { should be(true) }
    end

    context "when it's a different user" do
      let(:other) { create(:user) }

      it { should be(false) }
    end
  end

end
