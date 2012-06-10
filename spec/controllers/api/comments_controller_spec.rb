require 'spec_helper'

describe Api::CommentsController do

  let(:user)      { Factory(:user) }
  let(:asciicast) { Factory(:asciicast) }

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
          :comment => { "body" => "Foo" },
          :format => :json
      end

      before do
        Comment.any_instance.should_receive(:save).and_return(true)
      end

      it "response status should be 201" do
        dispatch
        response.status.should == 201
      end

      it "notifies asciicast author via email" do
        @controller.should_receive(:notify_via_email)
        dispatch
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

      it "calls destroy on comment" do
        comment.should_receive(:destroy)
        delete :destroy, :id => 1, :format => :json
      end

    end

    context "when user is not creator of comment" do
      let(:other_user) { Factory(:user) }

      before do
        comment.stub(:user).and_return(other_user)
      end

      it "doesn't call destroy on comment" do
        comment.should_not_receive(:destroy)
        delete :destroy, :id => 1, :format => :json
      end

      it "responses with 403 when xhr" do
        xhr :delete, :destroy, :id => 1, :format => :json
        response.status.should == 403
      end

    end
  end

  describe '#notify_via_email' do
    let(:user) { stub_model(User) }
    let(:comment) { stub_model(Comment) }

    context 'when asciicast author has email' do
      before do
        user.email = "jolka@pamietasz.pl"
      end

      context 'and he is not comment author' do
        before do
          comment.user = stub_model(User)
        end

        it "sends email" do
          mail = double('mail', :deliver => true)
          UserMailer.should_receive(:new_comment_email).and_return(mail)
          @controller.send(:notify_via_email, user, comment)
        end
      end

      context 'and he is comment author' do
        before do
          comment.user = user
        end

        it "doesn't send email" do
          UserMailer.should_not_receive(:new_comment_email)
          @controller.send(:notify_via_email, user, comment)
        end
      end
    end

    context 'when asciicast author has no email' do
      it "doesn't send email" do
        UserMailer.should_not_receive(:new_comment_email)
        @controller.send(:notify_via_email, user, comment)
      end
    end

    context 'when asciicast author is unknown (nil)' do
      let(:user) { nil }

      it "doesn't send email" do
        UserMailer.should_not_receive(:new_comment_email)
        @controller.send(:notify_via_email, user, comment)
      end
    end
  end
end
