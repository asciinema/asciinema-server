require 'spec_helper'

describe CommentDecorator do
  before { ApplicationController.new.set_current_view_context }

  let(:decorated_comment) { CommentDecorator.new(comment) }

  describe "#as_json" do
    let(:comment) { FactoryGirl.build(:comment) }

    it "includes user comment creator properties user" do
      hash = decorated_comment.as_json
      hash.should include(:user)
      hash[:user].should include("nickname")
      hash[:user].should include("avatar_url")
      hash[:user].should include("id")
    end

    it "should include comment.created" do
      decorated_comment.as_json.should include 'created'
    end
  end

  describe "#created" do
    let(:comment) { stub_model(Comment) }

    context "when created_at present" do
      before { comment.created_at = Time.now }

      it "returns string" do
        decorated_comment.created.should be_kind_of(String)
      end
    end

    context "no created_at" do
      before { comment.created_at = nil }

      it "returns string" do
        decorated_comment.created.should be_nil
      end
    end

  end

end
