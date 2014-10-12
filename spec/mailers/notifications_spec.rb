require "rails_helper"

RSpec.describe Notifications, :type => :mailer do
  describe "login_request" do
    let(:mail) { Notifications.login_request(user.id, "the-to-ken") }
    let(:user) { create(:user, email: "foo@example.com") }

    it "renders the headers" do
      expect(mail.subject).to eq("Login request")
      expect(mail.to).to eq(["foo@example.com"])
      expect(mail.from).to eq(["hello@asciinema.org"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Click")
      expect(mail.body.encoded).to match(login_token_path("the-to-ken"))
    end
  end

end
