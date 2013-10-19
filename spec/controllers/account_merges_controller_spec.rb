require 'spec_helper'

describe AccountMergesController do

  describe '#create' do
    subject { get :create, provider: 'twitter' }

    let(:credentials) { double('credentials') }
    let(:store) { {} }

    before do
      allow(controller).to receive(:omniauth_credentials) { credentials }
      allow(controller).to receive(:store) { store }
      allow(User).to receive(:for_credentials).with(credentials) { user }
      store[:new_user_email] = 'foo@bar.com'
    end

    context "when user can be found for given credentials" do
      let(:user) { stub_model(User) }

      before do
        allow(user).to receive(:update_attribute)
        allow(controller).to receive(:current_user=)

        subject
      end

      it 'updates the email on the user' do
        expect(user).to have_received(:update_attribute).
          with(:email, 'foo@bar.com')
      end

      it 'removes the email from the store' do
        expect(store.key?(:new_user_email)).to be(false)
      end

      it 'sets the current_user' do
        expect(controller).to have_received(:current_user=).with(user)
      end

      it 'redirects to the root_path with a notice' do
        expect(flash[:notice]).to_not be_blank
        should redirect_to(root_path)
      end
    end

    context "when user can't be found for given credentials" do
      let(:user) { nil }

      before do
        subject
      end

      it "doesn't remove the email from the store" do
        expect(store.key?(:new_user_email)).to be(true)
      end

      it 'redirects to new user page with an alert' do
        expect(flash[:alert]).to_not be_blank
        should redirect_to(new_user_path)
      end
    end
  end

end
