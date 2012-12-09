require 'spec_helper'

describe UserTokensController do
  describe '#create' do
    let(:user_token) { FactoryGirl.build(:user_token, :user => nil) }

    context 'for guest user' do
      before do
        get :create, :user_token => user_token.token
      end

      it { should redirect_to(login_path) }
      specify { flash[:notice].should =~ /login first/ }
    end

    context 'for authenticated user' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        login_as user
        user.stub!(:add_user_token => user_token)
        @controller.should_receive(:ensure_authenticated!)
      end

      context 'when given token is valid' do
        let(:claimed) { 5 }

        before do
          user_token.stub!(:valid? => true)

          Asciicast.should_receive(:assign_user).
                    with(user_token.token, user).
                    and_return(claimed)

          get :create, :user_token => user_token.token
        end

        it { should redirect_to(profile_path(user)) }

        context 'when 0 asciicasts were claimed' do
          let(:claimed) { 0 }

          specify { flash[:notice].should =~ /Authenticated/ }
        end

        context 'when more than 0 asciicasts were claimed' do
          let(:claimed) { 1 }

          specify { flash[:notice].should =~ /Claimed #{claimed}/ }
        end
      end

      context 'when given token is invalid' do
        before do
          user_token.stub!(:valid? => false)
        end

        it "doesn't call Asciicast.assign_user" do
          Asciicast.should_not_receive(:assign_user)

          get :create, :user_token => user_token.token
        end

        it 'renders :error' do
          get :create, :user_token => user_token.token

          response.should render_template(:error)
        end
      end
    end
  end
end
