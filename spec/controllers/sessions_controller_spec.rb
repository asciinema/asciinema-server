require 'spec_helper'

describe SessionsController do

  describe "#create" do
    subject { get :create, :provider => 'twitter' }

    shared_examples_for 'successful path' do
      it "creates the session" do
        subject

        expect(controller).to have_received(:current_user=).with(user)
      end

      it "sets the flash message" do
        subject

        expect(flash[:notice]).to eq('Logged in!')
      end

      it "redirects to the root url" do
        expect(subject).to redirect_to(root_url)
      end
    end

    before do
      request.env['asciiio.user'] = user
      allow(controller).to receive(:current_user=)
    end

    context "when user was persisted" do
      let(:user) { mock_model(User) }

      it_behaves_like 'successful path'
    end

    context "when user doesn't exist" do
      let(:user_attributes) { {
        :uid        => '1234',
        :provider   => 'github',
        :avatar_url => 'http://foo'
      } }

      let(:user) { mock_model(User, user_attributes).as_new_record }

      context "and creation succeeds" do
        before do
          allow(user).to receive(:save) { true }
        end

        it_behaves_like 'successful path'
      end

      context "and creation fails" do
        before do
          allow(user).to receive(:save) { false }
        end

        it "stores uid and provider in session " do
          subject

          expect(session[:new_user]).to eq({
            :uid => '1234', :provider => 'github', :avatar_url => 'http://foo'
          })
        end

        it "renders users/new" do
          expect(subject).to render_template('users/new')
        end
      end
    end
  end

  describe "#destroy" do
    before do
      session[:user_id] = "123"
      get :destroy
    end

    it "should destroy session" do
      session[:user_id].should be_nil
      @controller.current_user.should be_nil
    end

    it "should redirects to root_url" do
      flash[:notice].should == "Logged out!"
      should redirect_to(root_url)
    end
  end

  describe "#failure" do
    before do
      get :failure
    end

    it "should redirect to root_url and set error message" do
      flash[:alert].should =~ /Authentication failed/
      should redirect_to(root_url)
    end
  end

end
