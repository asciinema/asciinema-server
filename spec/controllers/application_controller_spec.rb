require 'spec_helper'

class FakesController < ApplicationController

  def foo
    raise Unauthorized
  end

  def bar
    raise Forbidden
  end

  def store
    store_location
    render :nothing => true
  end

  def retrieve
    @location = get_stored_location
    @location_again = get_stored_location || 'NOWAI!'
    render :nothing => true
  end
end

describe FakesController do

  before do
    @orig_routes, @routes = @routes, ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      resource :fake do
        get :foo
        get :bar
        get :store
        get :retrieve
      end
    end
  end

  after do
    @routes, @orig_routes = @orig_routes, nil
  end

  describe "#ensure_authenticated!" do
  end

  describe "action raise unauthorized" do

    context "when xhr" do
      before { request.stub(:xhr?).and_return(true) }

      it "response with 401" do
        get :foo

        response.status.should == 401
      end

    end

    context "when typical request" do

      it "redirects to login_path" do
        @controller.should_receive(:store_location)

        get :foo

        flash[:notice].should == "Please sign in to proceed"
        should redirect_to(login_path)
      end

    end
  end

  context "when action raise forbidden" do
    context "when xhr" do
      before { request.stub(:xhr?).and_return(true) }

      it "response with 401" do
        get :bar

        response.status.should == 403
      end
    end

    context "when typical request" do

      it "redirects to root_path" do
        get :bar

        flash[:alert].should == "This action is forbidden"
        should redirect_to(root_path)
      end

    end
  end

  describe '#store_location / #get_stored_location' do
    it 'stores current request path to be later retrieved' do
      get :store
      get :retrieve
      assigns[:location].should == '/fake/store'
      assigns[:location_again].should == 'NOWAI!'
    end
  end

  describe '#redirect_back_or_to' do
    context 'when there is no stored location' do
      it 'redirects to given location' do
        path = double
        @controller.should_receive(:redirect_to).with(path)
        @controller.send(:redirect_back_or_to, path)
      end
    end

    context 'when there is stored location' do
      it 'redirects to stored location' do
        stored_path = double
        path = double
        @controller.stub(:get_stored_location => stored_path)
        @controller.should_receive(:redirect_to).with(stored_path)
        @controller.send(:redirect_back_or_to, path)
      end
    end
  end

  describe '#current_user=' do
    let(:store) { {} }

    before do
      allow(store).to receive(:permanent) { store }
    end

    before do
      allow(controller).to receive(:permanent_store) { store }
      controller.current_user = user
    end

    context "with a user" do
      let(:user) { double('user', auth_token: '1b2c3') }

      it "stores user's auth_token in the permanent_store" do
        expect(store[:auth_token]).to eq('1b2c3')
      end
    end

    context "with nil" do
      let(:store) { { auth_token: 'a-token' } }
      let(:user) { nil }

      it "stores deletes the auth_token from the permanent_store" do
        expect(store.key?(:auth_token)).to eq(false)
      end
    end
  end

  describe '#current_user' do
    let(:user) { create(:user) }

    subject { controller.current_user }

    before do
      allow(controller).to receive(:permanent_store) { store }
    end

    context "when valid auth_token exists in the store" do
      let(:store) { { auth_token: user.auth_token } }

      it { should eq(user) }
    end

    context "when invalid auth_token exists in the store" do
      let(:store) { { auth_token: 'xxxx' } }

      it { should be(nil) }
    end

    context "when auth_token doesn't exist in the store" do
      let(:store) { {} }

      it { should be(nil) }
    end
  end

end
