require 'rails_helper'

describe LoginsController do

  describe "#new" do
    subject { get :new }

    it "renders 'new' template" do
      should render_template('new')
    end
  end

  describe "#create" do
    subject { post :create, email: "foo@example.com" }

    let(:login_service) { double(:login_service) }

    before do
      allow(controller).to receive(:login_service) { login_service }
      allow(login_service).to receive(:login).with("foo@example.com") { login_success }
    end

    context "when login succeeds" do
      let(:login_success) { true }

      it "sets email_recipient in flash" do
        subject
        expect(flash[:email_recipient]).to eq("foo@example.com")
      end

      it "redirects to 'sent' page" do
        should redirect_to(sent_login_path)
      end
    end

    context "when login fails" do
      let(:login_success) { false }

      it "renders 'new' template" do
        should render_template('new')
      end
    end
  end

  describe "#sent" do
    subject { get :sent, {}, {}, { email_recipient: email_recipient } }

    context "when email_recipient is set in flash" do
      let(:email_recipient) { "foo@example.com" }

      it "renders 'sent' template" do
        should render_template('sent')
      end
    end

    context "when email_recipient is not set in flash" do
      let(:email_recipient) { nil }

      it "redirects to login page" do
        should redirect_to(new_login_path)
      end
    end
  end

end
