require 'spec_helper'

describe UserTokensController do

  let(:user_token_creator) { double('user_token_creator') }

  before do
    allow(controller).to receive(:user_token_creator) { user_token_creator }
  end

  describe '#create' do
    let(:claimed_num) { 0 }
    let(:user_token) { build(:user_token, :user => nil) }
    let(:user) { create(:user) }

    before do
      login_as user
      allow(user_token_creator).to receive(:create).
        with(user, user_token.token) { claimed_num }
      get :create, user_token: user_token.token
    end

    context 'for guest user' do
      let(:user) { nil }

      it { should redirect_to(login_path) }
      specify { flash[:notice].should =~ /login first/ }
    end

    context "when # of claimed asciicasts is nil" do
      let(:claimed_num) { nil }

      it 'displays error page' do
        response.should render_template(:error)
      end
    end

    context "when # of claimed asciicast is 0" do
      let(:claimed_num) { 0 }

      it { should redirect_to(profile_path(user)) }
      specify { flash[:notice].should =~ /Authenticated/ }
    end

    context "when # of claimed asciicast is > 0" do
      let(:claimed_num) { 1 }

      it { should redirect_to(profile_path(user)) }
      specify { flash[:notice].should =~ /Claimed #{claimed_num}/ }
    end
  end

end
