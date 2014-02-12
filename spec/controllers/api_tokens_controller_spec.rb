require 'spec_helper'

describe ApiTokensController do

  describe '#create' do
    subject { get :create, api_token: 'a-toh-can' }

    let(:user) { double('user', assign_api_token: nil) }

    before do
      login_as(user)
    end

    context 'for guest user' do
      let(:user) { nil }

      before do
        subject
      end

      it { should redirect_to(login_path) }

      specify { expect(flash[:notice]).to match(/sign in to proceed/) }
    end

    context "when assigning succeeds" do
      before do
        allow(user).to receive(:assign_api_token).with('a-toh-can')
        subject
      end

      it { should redirect_to(profile_path(user)) }

      specify { expect(flash[:notice]).to_not be_blank }
    end

    context "when token is invalid" do
      before do
        allow(user).to receive(:assign_api_token).with('a-toh-can').
          and_raise(ActiveRecord::RecordInvalid, ApiToken.new)
      end

      it 'displays error page' do
        expect(subject).to render_template(:error)
      end
    end

    context "when token is taken" do
      before do
        allow(user).to receive(:assign_api_token).with('a-toh-can').
          and_raise(ApiToken::ApiTokenTakenError)
      end

      it 'displays error page' do
        expect(subject).to render_template(:error)
      end
    end
  end

end
