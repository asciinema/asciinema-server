require 'spec_helper'
require 'rack/mock'

describe AuthCookieStrategy do

  let(:strategy) { described_class.new(env) }
  let(:env) { Rack::MockRequest.env_for('', 'HTTP_COOKIE' => cookies) }

  describe '#valid?' do
    subject { strategy.valid? }

    context "when auth_token is present in cookies" do
      let(:cookies) { 'auth_token=abc' }

      it { should be(true) }
    end

    context "when auth_token isn't present in cookies" do
      let(:cookies) { '' }

      it { should be(false) }
    end
  end

  describe '#authenticate!' do
    subject { strategy.authenticate! }

    let(:cookies) { "auth_token=#{auth_token}" }

    context "when valid token given" do
      let(:auth_token) { user.auth_token }
      let(:user) { create(:user) }

      it "halts the chain" do
        subject

        expect(strategy).to be_halted
      end

      it "sets the proper user" do
        subject

        expect(strategy.user).to eq(user)
      end
    end

    context "when invalid token given" do
      let(:auth_token) { "yadayadayada" }

      it "doesn't halt the chain" do
        subject

        expect(strategy).to_not be_halted
      end

      it "doesn't set user" do
        subject

        expect(strategy.user).to be(nil)
      end
    end
  end

end
