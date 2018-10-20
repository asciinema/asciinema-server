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
