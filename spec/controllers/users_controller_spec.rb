require 'spec_helper'

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

    subject { post :create, user: { nickname: 'jola' } }

    before do
      allow(controller).to receive(:current_user=)
      allow(User).to receive(:new).with('nickname' => 'jola') { user }
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
        should redirect_to(docs_path(:gettingstarted))
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
    it 'should have specs'
  end

  describe '#edit' do
    it 'should have specs'
  end

  describe '#update' do
    it 'should have specs'
  end

end
