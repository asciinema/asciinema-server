require 'spec_helper'

describe AsciicastsController do
  let(:user) { stub_model(User) }
  let(:asciicast) { stub_model(Asciicast, :id => 666) }

  subject { response }

  describe '#index' do
    before do
      get :index
    end

    it { should be_success }
  end

  describe '#show' do
    before do
      Asciicast.should_receive(:find).and_return(asciicast)
      get :show, :id => asciicast.id
    end

    it { should be_success }
  end

  describe '#edit' do
    before do
      Asciicast.should_receive(:find).and_return(asciicast)
      asciicast.user = user
      login_as user
      get :edit, :id => asciicast.id
    end

    it { should be_success }
  end

  describe '#update' do
    before do
      Asciicast.should_receive(:find).and_return(asciicast)
      asciicast.user = user
      login_as user
      put :update, :id => asciicast.id, :asciicast => { }
    end

    it { should redirect_to(asciicast_path(asciicast)) }
  end

  describe '#destroy' do
    before do
      Asciicast.should_receive(:find).and_return(asciicast)
      asciicast.user = user
      login_as user
    end

    context 'when destroy succeeds' do
      before do
        asciicast.should_receive(:destroy).and_return(true)
        delete :destroy, :id => asciicast.id
      end

      it { should redirect_to(profile_path(nil)) }
    end

    context 'when destroy fails' do
      before do
        asciicast.should_receive(:destroy).and_return(false)
        delete :destroy, :id => asciicast.id
      end

      it { should redirect_to(asciicast_path(asciicast)) }
    end
  end
end
