require 'spec_helper'

describe OauthHelper do
  describe ".avatar_url" do
    let(:avatar_url) { "http://foo.bar/foo.png" }

    context "when github auth" do
      let(:auth) do
        {
          "provider" => "github",
          "extra_info" => {
            "avatar_url" => avatar_url
          }
        }
      end

      it { OauthHelper.get_avatar_url(auth).should == avatar_url}

    end

    context "when twitter auth" do
      let(:auth) do
        {
          "provider" => "twitter",
          "info" => {
            "image" => avatar_url
          }
        }
      end

      it { OauthHelper.get_avatar_url(auth).should == avatar_url}
    end

    context "when other provider" do
      let(:auth) do
        { "provider" => "other" }
      end

      it { OauthHelper.get_avatar_url(auth).should be_nil }
    end
  end
end
