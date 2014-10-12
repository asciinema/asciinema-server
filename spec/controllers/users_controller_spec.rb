require 'rails_helper'

describe UsersController do

  describe '#show' do
    subject { get :show, username: username }

    let(:username) { user.username }

    before do
      subject
    end

    context "when confirmed user username given" do
      let(:user) { create(:user) }

      it 'renders "show" template' do
        should render_template('show')
      end
    end

    context "when unconfirmed user username given" do
      let(:user) { create(:unconfirmed_user) }

      it "responds with 404" do
        expect(subject).to be_not_found
      end
    end

    context "when fictional username given" do
      let(:username) { 'nononono-no' }

      it "responds with 404" do
        expect(subject).to be_not_found
      end
    end
  end

  describe '#edit' do
    subject { get :edit }

    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    it "is successful" do
      subject
      expect(response.status).to eq(200)
    end

    it 'renders "edit" template' do
      subject
      expect(response).to render_template(:edit)
    end

    context "for guest user" do
      before do
        logout
      end

      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_login_path)
      end
    end
  end

  describe '#update' do
    subject { put :update, user: { username: new_username } }

    let(:user) { create(:user) }
    let(:new_username) { 'batman' }

    before do
      login_as(user)
    end

    it "redirects to profile" do
      subject
      expect(response).to redirect_to(public_profile_path(username: 'batman'))
    end

    context "when update fails" do
      let(:new_username) { '' }

      it "responds with 422 status code" do
        subject
        expect(response.status).to eq(422)
      end

      it 'renders "edit" template' do
        subject
        expect(response).to render_template(:edit)
      end
    end

    context "for guest user" do
      before do
        logout
      end

      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_login_path)
      end
    end
  end

end
