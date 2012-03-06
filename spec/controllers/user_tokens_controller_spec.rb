require 'spec_helper'

describe UserTokensController do
  describe '#create' do
    let(:user) { Factory(:user) }
    let(:user_token) { FactoryGirl.build(:user_token, :user => nil) }

    before do
      login_as user
      user.stub!(:add_user_token => user_token)
      @controller.should_receive(:ensure_authenticated!)
    end

    context 'when given token is valid' do
      before do
        user_token.stub!(:valid? => true)
      end

      it 'calls Asciicast.assign_user' do
        Asciicast.should_receive(:assign_user).with(user_token.token, user).and_return(1)

        post :create, :user_token => user_token.token
      end

      it 'redirects to ~nickname' do
        post :create, :user_token => user_token.token

        response.should redirect_to(profile_path(user))
      end
    end

    context 'when given token is invalid' do
      before do
        user_token.stub!(:valid? => false)
      end

      it 'calls Asciicast.assign_user' do
        Asciicast.should_not_receive(:assign_user)

        post :create, :user_token => user_token.token
      end

      it 'renders :error' do
        post :create, :user_token => user_token.token

        response.should render_template(:error)
      end
    end
  end
end
