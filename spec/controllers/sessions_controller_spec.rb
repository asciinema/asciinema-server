require 'spec_helper'

describe SessionsController do

  let(:store) { {} }

  before do
    allow(controller).to receive(:store) { store }
  end

  describe '#new' do
    subject { get :new }

    it 'renders "new" template' do
      should render_template('new')
    end
  end

  describe '#create' do
    subject { get :create, provider: 'twitter' }

    let(:credentials) { double('credentials', email: 'foo@bar.com') }

    before do
      allow(controller).to receive(:omniauth_credentials) { credentials }
      allow(User).to receive(:for_email).with('foo@bar.com') { user }
    end

    context "when user can be found for given credentials" do
      let(:user) { stub_model(User) }

      before do
        allow(controller).to receive(:current_user=)

        subject
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

      it 'stores the email' do
        expect(store[:new_user_email]).to eq('foo@bar.com')
      end

      it 'redirects to the new user page' do
        should redirect_to(new_user_path)
      end
    end
  end

  describe "#destroy" do
    before do
      allow(controller).to receive(:current_user=)

      get :destroy
    end

    it 'sets current_user to nil' do
      expect(controller).to have_received(:current_user=).with(nil)
    end

    it "redirects to root_path with a notice" do
      expect(flash[:notice]).to_not be_blank
      should redirect_to(root_path)
    end
  end

  describe "#failure" do
    before do
      get :failure
    end

    it "redirects to root_url with an alert" do
      expect(flash[:alert]).to_not be_blank
      should redirect_to(root_path)
    end
  end

end
