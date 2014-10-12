require 'rails_helper'

describe EmailLoginService do

  let(:creator) { described_class.new }

  describe "#login" do
    subject { creator.login(email) }

    let(:email) { "me@example.com" }

    context "when given email is blank" do
      let(:email) { nil }

      it "returns false" do
        expect(subject).to be(false)
      end
    end

    context "when given email is invalid" do
      let(:email) { "oops" }

      it "returns false" do
        expect(subject).to be(false)
      end
    end

    context "when there's no user with given email" do
      it "creates a user with given email" do
        expect { subject }.to change(User, :count).by(1)
        expect(User.last.email).to eq("me@example.com")
      end

      it "creates an expiring token for new user" do
        expect { subject }.to change(ExpiringToken, :count).by(1)
        expect(ExpiringToken.last.user).to eq(User.last)
      end

      it "sends login email" do
        expect(Notifications).to receive(:delay_login_request)
        subject
      end

      it "returns true" do
        expect(subject).to be(true)
      end
    end

    context "when there's a user with given email" do
      let!(:user) { create(:user, email: "me@example.com") }

      it "creates an expiring token this user" do
        expect { subject }.to change(ExpiringToken, :count).by(1)
        expect(ExpiringToken.last.user).to eq(user)
      end

      it "sends login email" do
        expect(Notifications).to receive(:delay_login_request)
        subject
      end

      it "returns true" do
        expect(subject).to be(true)
      end
    end
  end

  describe "#validate" do
    subject { creator.validate(token) }

    let(:token) { "the-to-ken" }

    context "when given token is valid" do
      let!(:expiring_token) { create(:expiring_token, user: user, token: token) }
      let(:user) { create(:user) }

      it "marks token as used" do
        now = Time.now

        Timecop.freeze(now) do
          subject
        end

        expect(expiring_token.reload.used_at.to_i).to eq(now.to_i)
      end

      it "returns user associated with the token" do
        expect(subject).to eq(user)
      end
    end

    context "when given token is invalid" do
      it "returns nil" do
        expect(subject).to be(nil)
      end
    end
  end

end
