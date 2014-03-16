require 'spec_helper'

describe "Asciicast retrieval" do

  let(:asciicast) { create(:asciicast) }

  context "when requested as js" do
    before do
      get "/a/#{asciicast.id}.js"
    end

    it "responds with status 200" do
      expect(response.status).to eq(200)
    end

    it "responds with javascript content type" do
      expect(response.headers['Content-Type']).to match('text/javascript')
    end

    it "responds with embeddable player code" do
      expect(response.body).to match(/iframe/)
    end
  end

  context "when requested as html" do
    include Capybara::RSpecMatchers

    before do
      get "/api/asciicasts/#{asciicast.id}", format: 'html'
    end

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
      expect(response.body).to have_selector('body.iframe div.player')
    end
  end

end
