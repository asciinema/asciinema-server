require 'spec_helper'

describe CommentsController do

  let(:user)      { mock_model(User) }
  let(:asciicast) { mock_model(Asciicast) }

  it "should ensure user is authenticated" do

  end

  before do
    Asciicast.stub(:find).and_return(asciicast)
    login_as(user)
  end

  describe "#create" do

    context "given valid data" do
      def dispatch
        post :create,
          :asciicast_id => asciicast.id,
          :comment => {"body" => "Foo"},
          :format => :json
      end

      before do
        Comment.any_instance.should_receive(:save).and_return(true)
      end

      it "assigns current_user" do
        dispatch
        assigns(:comment).user.should_not be_blank
      end

      it "assigns asciicast" do
        dispatch
        assigns(:comment).asciicast.should_not be_blank
      end

      it "assigns asciicast" do
        dispatch
        response.status.should == 201
      end
    end

    context "given not valid data" do
      def dispatch
        post :create,
          :asciicast_id => asciicast.id,
          :comment => {},
          :format => :json
      end

      it "response should be 422" do
        dispatch
        response.status.should == 422
      end
    end
  end

  describe "#index" do

    it "return comments" do
      asciicast.should_receive(:comments).and_return([])
      get :index, :asciicast_id => asciicast.id
    end

  end

end
