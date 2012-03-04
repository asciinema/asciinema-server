require 'spec_helper'

describe Comment do

  it "factory should be valid" do
    Factory.build(:comment).should be_valid
  end

  describe "#as_json" do
    let(:user) { Factory(:user) }
    let(:comment) { Factory.build(:comment) }

    before do
      comment.user = user
    end

    it "should include user comment creator properties user" do
      hash = comment.as_json
      hash.should include(:user)
      hash[:user].should include("nickname")
      hash[:user].should include("avatar_url")
      hash[:user].should include("id")
    end

    it "should include comment.created" do
      comment.as_json.should include :created
    end
  end

end
