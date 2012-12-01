require 'spec_helper'

describe SessionsController do

  describe "#create" do
    let(:provider) { "twitter" }
    let(:uid)      { 1234 }
    let(:nickname) { "mrFoo" }

    before do
      OmniAuth.config.mock_auth[:twitter] = {
        "provider" => provider,
        "uid" => uid,
        "info" => { "nickname" => nickname }
      }

      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]
    end

    context "user exists" do
      before do
        FactoryGirl.create(:user, :provider => provider, :uid => uid)
        post :create
      end

      it "should create session" do
        session[:user_id].should_not be_nil
        @controller.current_user.should_not be_nil
      end

      it "should redirects user to root url" do
        flash[:notice].should == "Logged in!"
        should redirect_to(root_url)
      end
    end

    context "user doesn't exist" do
      let(:auth) { request.env["omniauth.auth"] }
      let(:user) { stub("user", :id => 1, :persisted? => true) }

      context "when nicknamne is not taken" do
        it "should call create_with_omniauth" do
          User.should_receive(:create_with_omniauth).
            with(auth).
            and_return(user)

          post :create
        end

        it "should login user" do
          User.stub(:create_with_omniauth).and_return(user)

          post :create

          session[:user_id].should_not be_nil
        end
      end

      context "when nicknamne is taken" do
        let(:not_saved_user) {
          stub_model(User,
            :persisted? => false,
            :valid?     => false,
            :uid        => uid,
            :provider   => provider
          )
        }

        before do
          User.stub(:create_with_omniauth).and_return(not_saved_user)
        end

        it "puts uid and provider in session " do
          post :create

          session[:new_user][:uid].should == uid
          session[:new_user][:provider].should == provider
        end

        it "renders user/new" do
          post :create
          should render_template('users/new')
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
    let(:message) { "something went wrong" }

    before do
      get :failure, :message => message
    end

    it "should redirects to root_url and set error message" do
      flash[:alert].should == message
      should redirect_to(root_url)
    end
  end

end
