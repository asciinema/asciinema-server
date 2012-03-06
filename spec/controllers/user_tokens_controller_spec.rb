require 'spec_helper'

describe UserTokensController do
  describe '#create' do
    let(:user) { Factory(:user) }
    let(:user_token) { FactoryGirl.build(:user_token, :user => nil) }

    before do
      @controller.stub!(:current_user => user)
      user.stub!(:add_user_token => user_token)
    end

    context 'when given token is valid' do
      before do
        user_token.stub!(:valid? => true)
      end

      it 'calls Asciicast.assign_user' do
        Asciicast.should_receive(:assign_user).with(user_token.token, user).and_return(1)

        post :create, :user_token => user_token.token
      end

      it 'redirects to root_path' do
        post :create, :user_token => user_token.token

        response.should redirect_to(root_path)
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
