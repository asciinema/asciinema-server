require 'rails_helper'

describe SessionsController do

  describe "#new" do
    subject { get :new, token: 'the-to-ken' }

    before do
      subject
    end

    it "displays button" do
      should render_template('new')
    end
  end

  describe "#create" do
    subject { post :create, token: 'the-to-ken' }

    let(:login_service) { double(:login_service) }

    before do
      allow(controller).to receive(:login_service) { login_service }
      allow(login_service).to receive(:validate).with('the-to-ken') { user }
    end

    context "when token is successfully validated" do
      let(:user) { stub_model(User) }

      before do
        allow(controller).to receive(:current_user=)

        subject
      end

      it "sets the current_user" do
        expect(controller).to have_received(:current_user=).with(user)
      end

      it "sets a notice" do
        expect(flash[:notice]).to_not be_blank
      end

      context "when user has username" do
        let(:user) { User.new(username: "foobar") }

        it "redirects to user's profile" do
          should redirect_to(public_profile_path(username: "foobar"))
        end
      end

      context "when user has no username" do
        let(:user) { User.new }

        it "redirects to new username page" do
          should redirect_to(new_username_path)
        end
      end
    end

    context "when token is not validated" do
      let(:user) { nil }

      before do
        subject
      end

      it "displays error" do
        should render_template('error')
      end
    end
  end

  describe "#destroy" do
    before do
      allow(controller).to receive(:current_user=)

      get :destroy
    end

    it "sets current_user to nil" do
      expect(controller).to have_received(:current_user=).with(nil)
    end

    it "redirects to root_path with a notice" do
      expect(flash[:notice]).to_not be_blank
      should redirect_to(root_path)
    end
  end

end
