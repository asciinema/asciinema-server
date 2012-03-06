require 'spec_helper'

class FakeController < ApplicationController

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

describe FakeController do

  describe "#ensure_authenticated!" do
  end

  describe "action raise unauthorized" do

    context "when xhr" do
      before{ request.stub(:xhr?).and_return(true) }

      it "response with 401" do
        get :foo

        response.status.should == 401
      end

    end

    context "when typical request" do

      it "redirects to login_path" do
        @controller.should_receive(:store_location)

        get :foo

        flash[:notice].should == "Please login"
        should redirect_to(login_path)
      end

    end
  end

  context "when action raise forbidden" do
    context "when xhr" do
      before{ request.stub(:xhr?).and_return(true) }

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
      get :store # request.path is '/assets' (???)
      get :retrieve
      assigns[:location].should == '/assets'
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
        @controller.stub!(:get_stored_location => stored_path)
        @controller.should_receive(:redirect_to).with(stored_path)
        @controller.send(:redirect_back_or_to, path)
      end
    end
  end
end

