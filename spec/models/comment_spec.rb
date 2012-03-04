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

    it "includes user comment creator properties user" do
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

  describe "#created" do
    let(:time) { Time.new(2012, 01, 03) }
    let(:expected) { time.strftime("%Y-%m-%dT%H:%M:%S") }
    let(:comment) { Factory.build(:comment) }

    context "when created_at present" do
      before { comment.stub(:created_at).and_return(time) }

      it "returns js parsable format" do
        comment.created.should == expected
      end
    end

    context "no created_at" do
      it { comment.created_at.should be_nil }
    end

  end
end
