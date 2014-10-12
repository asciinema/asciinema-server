require 'rails_helper'

describe UsersController do

  let(:store) { {} }

  before do
    allow(controller).to receive(:store) { store }
  end

  describe '#new' do
    before do
      store[:new_user_email] = 'foo@bar.com'

      get :new
    end

    it 'assigns user with a stored email' do
      expect(assigns(:user).email).to eq('foo@bar.com')
    end

    it 'renders new template' do
      should render_template('new')
    end
  end

  describe "#create" do
    let!(:user) { stub_model(User) }

    subject { post :create, user: { username: 'jola' } }

    before do
      allow(controller).to receive(:current_user=)
      allow(User).to receive(:new).with('username' => 'jola') { user }
      store[:new_user_email] = 'foo@bar.com'
    end

    context "when user is persisted" do
      before do
        allow(user).to receive(:save) { true }

        subject
      end

      it 'removes the email from the store' do
        expect(store.key?(:new_user_email)).to be(false)
      end

      it 'assigns the stored email to the user' do
        expect(user.email).to eq('foo@bar.com')
      end

      it 'sets the current_user' do
        expect(controller).to have_received(:current_user=).with(user)
      end

      it 'redirects to the "getting started" page with a notice' do
        expect(flash[:notice]).to_not be_blank
        should redirect_to(docs_path('getting-started'))
      end
    end

    context "when user isn't persisted" do
      before do
        allow(user).to receive(:save) { false }

        subject
      end

      it "doesn't remove the email from the store" do
        expect(store.key?(:new_user_email)).to be(true)
      end

      it "doesn't set the current_user" do
        expect(controller).to_not have_received(:current_user=)
      end

      it 'assigns user with a stored email' do
        expect(assigns(:user).email).to eq('foo@bar.com')
      end

      it 'renders "new" template' do
        should render_template('new')
      end
    end
  end

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
