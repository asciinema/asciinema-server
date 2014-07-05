require 'spec_helper'

describe UserPolicy do

  subject { described_class }

  permissions :update? do
    it "grants access if edited user is current user" do
      user = User.new
      expect(subject).to permit(user, user)
    end

    it "denies access if edited user is not current user" do
      expect(subject).not_to permit(User.new, User.new)
    end
  end

end
