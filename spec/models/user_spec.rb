require 'spec_helper'

describe User do

  describe "#valid?" do
    before do
      create(:user)
    end

    it { should validate_uniqueness_of(:nickname) }
    it { should validate_uniqueness_of(:email) }
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
