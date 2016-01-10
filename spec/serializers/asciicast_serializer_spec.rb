require 'rails_helper'

describe AsciicastSerializer do

  let(:serializer) { AsciicastSerializer.new(asciicast, playback_options: PlaybackOptions.new) }
  let(:asciicast) { create(:asciicast) }

  describe '#to_json' do
    subject { JSON.parse(serializer.to_json) }

    it 'includes id' do
      expect(subject['id']).to eq(asciicast.to_param)
    end

    it 'includes url' do
      expect(subject['url']).to eq("/a/#{asciicast.to_param}.json")
    end

    it 'includes snapshot' do
      expect(subject['snapshot']).to eq(asciicast.snapshot)
    end

    it 'includes width' do
      expect(subject['width']).to eq(asciicast.terminal_columns)
    end

    it 'includes height' do
      expect(subject['height']).to eq(asciicast.terminal_lines)
    end
  end

end
