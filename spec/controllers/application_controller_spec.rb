require 'spec_helper'

class FakeController < ApplicationController

  def foo
    raise Unauthorized
  end

  def bar
    raise Forbiden
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
        get :foo

        flash[:notice].should == "Please login"
        should redirect_to(login_path)
      end

    end
  end

  context "when action raise forbiden" do
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

        flash[:alert].should == "This action is forbiden"
        should redirect_to(root_path)
      end

    end
  end

end

