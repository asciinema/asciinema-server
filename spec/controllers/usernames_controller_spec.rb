require 'rails_helper'

describe UsernamesController do

  let(:user) { stub_model(User) }

  before do
    login_as user
    allow(User).to receive(:find) { user }
  end

  describe "#new" do
    subject { get :new }

    it "renders 'new' template" do
      should render_template('new')
    end
  end

  describe "#create" do
    subject { post :create, user: { username: 'doppelganger' } }


    before do
      allow(user).to receive(:update).with(username: 'doppelganger') { success }
      subject
    end

    context "when username is updated" do
      let(:success) { true }

      it "redirects to user's profile" do
        should redirect_to(unnamed_user_path(user))
      end
    end

    context "when username is not updated" do
      let(:success) { false }

      it "displays error" do
        should render_template('new')
      end
    end
  end

  describe "#skip" do
    pending
  end

end
