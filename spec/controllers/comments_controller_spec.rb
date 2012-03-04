require 'spec_helper'

describe CommentsController do

  let(:user)      { Factory(:user) }
  let(:asciicast) { mock_model(Asciicast) }

  before do
    login_as(user)
  end

  describe "#create" do
    before do
      Asciicast.stub(:find).and_return(asciicast)
    end

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
    before do
      Asciicast.stub(:find).and_return(asciicast)
    end

    it "return comments" do
      asciicast.should_receive(:comments).and_return([])
      get :index, :asciicast_id => asciicast.id
    end

  end

  describe "#destroy" do
    let(:comment) { mock_model(Comment).as_null_object }
    before do
      Comment.stub(:find).with("1").and_return(comment)
    end

    context "when user is creator of comment" do
      before do
        comment.stub(:user).and_return(user)
      end

      it "calls delete on comment" do
        comment.should_receive(:delete)
        delete :destroy, :id => 1, :format => :json
      end

    end

    context "when user is not creator of comment" do
      let(:other_user) { Factory(:user) }

      before do
        comment.stub(:user).and_return(other_user)
      end

      it "doesn't call delete on comment" do
        comment.should_not_receive(:delete)
        delete :destroy, :id => 1, :format => :json
      end

      it "responses with 403 when xhr" do
        xhr :delete, :destroy, :id => 1, :format => :json
        response.status.should == 403
      end

    end
  end
end
