require 'rails_helper'

class FakesController < ApplicationController

  def foo
    ensure_authenticated!
  end

  def bar
    raise Pundit::NotAuthorizedError
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

  describe "action raise unauthorized" do
    context "when xhr" do
      before { allow(request).to receive(:xhr?).and_return(true) }

      it "responds with 401" do
        get :foo

        expect(response.status).to eq(401)
      end
    end

    context "when normal request" do
      it "redirects to login page" do
        expect(@controller).to receive(:store_location)

        get :foo

        expect(flash[:notice]).to eq("Please log in to proceed")
        should redirect_to(new_login_path)
      end
    end
  end

  context "when action raises Pundit::NotAuthorizedError" do
    context "when xhr" do
      before { allow(request).to receive(:xhr?).and_return(true) }

      it "responds with 403" do
        get :bar

        expect(response.status).to eq(403)
      end
    end

    context "when normal request" do
      it "redirects to root_path" do
        get :bar

        expect(flash[:alert]).to_not be(nil)
        should redirect_to(root_path)
      end
    end
  end

  describe '#store_location / #get_stored_location' do
    it 'stores current request path to be later retrieved' do
      get :store
      get :retrieve
      expect(assigns[:location]).to eq('/fake/store')
      expect(assigns[:location_again]).to eq('NOWAI!')
    end
  end

  describe '#redirect_back_or_to' do
    context 'when there is no stored location' do
      it 'redirects to given location' do
        path = double
        expect(@controller).to receive(:redirect_to).with(path)
        @controller.send(:redirect_back_or_to, path)
      end
    end

    context 'when there is stored location' do
      it 'redirects to stored location' do
        stored_path = double
        path = double
        allow(@controller).to receive(:get_stored_location) { stored_path }
        expect(@controller).to receive(:redirect_to).with(stored_path)
        @controller.send(:redirect_back_or_to, path)
      end
    end
  end

end
