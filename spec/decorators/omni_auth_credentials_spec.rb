require 'spec_helper'

describe OmniAuthCredentials do

  let(:credentials) { described_class.new(omniauth_hash) }

  let(:omniauth_hash) { {
    'provider' => 'twitter',
    'uid'      => '1234567',
    'info'     => { 'email' => 'foo@bar.com' }
  } }

  describe '#provider' do
    subject { credentials.provider }

    it { should eq('twitter') }
  end

  describe '#uid' do
    subject { credentials.uid }

    it { should eq('1234567') }
  end

  describe '#email' do
    subject { credentials.email }

    it { should eq('foo@bar.com') }

    context "when no info section in hash" do
      let(:omniauth_hash) { {
        'provider' => 'twitter',
        'uid'      => '1234567'
      } }

      it { should be(nil) }
    end
  end

end
