require 'spec_helper'

describe OmniAuthUserLoader do
  let(:middleware) { OmniAuthUserLoader.new(app) }
  let(:app) { double('app', :call => nil) }

  describe '#call' do
    let(:env) { { :path => '/foo' } }

    subject { env['asciiio.user'] }

    before do
      OmniAuth.config.mock_auth[:twitter] = omniauth
      env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]
    end

    context "when there's no omniauth hash" do
      let(:omniauth) { nil }

      before do
        middleware.call(env)
      end

      it { should be(nil) }
    end

    context "when the omniauth hash is present" do
      let(:omniauth) { {
        "provider" => 'twitter',
        "uid"      => 1234,
        "info"     => {
          "nickname" => 'quux',
          "name"     => 'Quux'
        }
      } }

      context "user exists" do
        let!(:user) { create(:user, :provider => 'twitter', :uid => 1234) }

        before do
          middleware.call(env)
        end

        it { should eq(user) }
      end

      context "user doesn't exist" do
        before do
          allow(OauthHelper).to receive(:get_avatar_url) { 'http://foo.bar/avatar.jpg' }
          middleware.call(env)
        end

        it { should be_new_record }

        its(:provider)   { should eq('twitter') }
        its(:uid)        { should eq(1234) }
        its(:nickname)   { should eq('quux') }
        its(:name)       { should eq('Quux') }
        its(:avatar_url) { should eq('http://foo.bar/avatar.jpg') }
      end
    end
  end
end
