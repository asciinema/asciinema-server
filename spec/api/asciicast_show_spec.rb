require 'rails_helper'

shared_examples_for "asciicast iframe response" do
  it "responds with status 200" do
    expect(response.status).to eq(200)
  end

  it "responds with html content type" do
    expect(response.headers['Content-Type']).to match('text/html')
  end

  it "responds without X-Frame-Options header" do
    pending "the header is added back by Rails only in tests O_o"
    expect(response.headers).to_not have_key('Content-Type')
  end

  it "responds with player page using iframe layout" do
    expect(response.body).to have_selector('body.iframe asciinema-player')
  end
end

describe "Asciicast retrieval" do

  let(:asciicast) { create(:asciicast) }

  context "when requested as js" do
    before do
      get "/a/#{asciicast.id}.js"
    end

    it "responds with status 302" do
      expect(response.status).to eq(302)
    end
  end

  context "when requested as html" do
    include Capybara::RSpecMatchers

    before do
      get "/a/#{asciicast.to_param}/embed", format: 'html'
    end

    it_behaves_like "asciicast iframe response"

    context "for private asciicast" do
      let(:asciicast) { create(:asciicast, private: true) }

      it_behaves_like "asciicast iframe response"
    end
  end

end
