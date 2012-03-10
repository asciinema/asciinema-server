require 'spec_helper'

describe "users/new" do
  let(:user) { FactoryGirl.build(:user) }

  before do
    assign(:user, user)
  end

  it "renders form with attr" do
    render
    rendered.should =~ /user\[nickname\]/
    rendered.should =~ /user\[name\]/
    rendered.should =~ /user\[avatar_url\]/
  end
end
