require 'spec_helper'

describe AsciicastSerializer do

  let(:serializer) { described_class.new(asciicast) }
  let(:asciicast) { create(:asciicast) }

  describe '#to_json' do
    subject { JSON.parse(serializer.to_json) }

    it 'includes id' do
      expect(subject['id']).to eq(asciicast.id)
    end

    it 'includes duration' do
      expect(subject['duration']).to eq(asciicast.duration)
    end

    it 'includes stdout_frames_url' do
      expect(subject['stdout_frames_url']).to eq(asciicast.stdout_frames_url)
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
