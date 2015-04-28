require 'rails_helper'

describe UserPolicy do

  subject { described_class }

  describe '#permitted_attributes' do
    subject { Pundit.policy(user, user).permitted_attributes }

    let(:user) { User.new }

    it "includes basic form fields" do
      expect(subject).to eq([:username, :name, :email, :theme_name])
    end

    context "when user is a supporter" do
      let(:user) { stub_model(User, supporter?: true) }

      it "also includes asciicasts_private_by_default" do
        expect(subject).to eq([:username, :name, :email, :theme_name, :asciicasts_private_by_default])
      end
    end
  end

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
