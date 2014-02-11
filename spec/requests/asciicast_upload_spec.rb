require 'spec_helper'

describe "Asciicast upload" do
  subject { response.body }

  before do
    post '/api/asciicasts', asciicast: {
      meta:          fixture_file(meta_filename, 'application/json'),
      stdout:        fixture_file('stdout', 'application/octet-stream'),
      stdout_timing: fixture_file('stdout.time', 'application/octet-stream')
    }
  end

  let(:meta_filename) { 'meta.json' }

  it 'returns the URL to the uploaded asciicast' do
    expect(response.body).to eq(asciicast_url(Asciicast.last))
  end

  context "when json includes uname (legacy)" do
    let(:meta_filename) { 'meta-with-uname.json' }

    it 'returns the URL to the uploaded asciicast' do
      expect(response.body).to eq(asciicast_url(Asciicast.last))
    end
  end

  context "when json doesn't include user_token (anonymous?)" do
    let(:meta_filename) { 'meta-no-token.json' }

    it 'returns the URL to the uploaded asciicast' do
      expect(response.body).to eq(asciicast_url(Asciicast.last))
    end
  end

end
