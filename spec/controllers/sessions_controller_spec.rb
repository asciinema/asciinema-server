require 'spec_helper'

describe SessionsController do

  describe "#create" do
    let(:provider) { "twitter" }
    let(:uid)      { 1234 }

    before do
      OmniAuth.config.mock_auth[:twitter] = {
        "provider" => provider,
        "uid" => uid
      }

      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]
    end

    context "user exists" do
      before do
        Factory(:user, :provider => provider, :uid => uid)
        post :create
      end

      it "should create session" do
        session[:user_id].should_not be_nil
        @controller.current_user.should_not be_nil
      end

      it "should redirects user to root url" do
        flash[:notice].should == "Signed in!"
        should redirect_to(root_url)
      end
    end

    context "user doesn't exist" do
      let(:auth) { request.env["omniauth.auth"] }
      let(:user) { stub("user", :id => 1) }

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
      flash[:notice].should == "Signed out!"
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
