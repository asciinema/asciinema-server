require 'rails_helper'

describe ApiTokenPolicy do

  subject { described_class }

  permissions :destroy? do
    it "denies access if user is nil" do
      expect(subject).not_to permit(nil, ApiToken.new)
    end

    it "grants access if user is admin" do
      user = stub_model(User, admin?: true)
      expect(subject).to permit(user, ApiToken.new)
    end

    it "grants access if user is the owner of the token" do
      user = stub_model(User, admin?: false)
      expect(subject).to permit(user, ApiToken.new(user: user))
    end

    it "denies access if user isn't the owner of the token" do
      expect(subject).not_to permit(User.new, ApiToken.new(user: User.new))
    end
  end

end
