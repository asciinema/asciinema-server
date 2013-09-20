require 'spec_helper'

describe AsciicastSerializer do
  let(:serializer) { described_class.new(asciicast) }
  let(:asciicast) { create(:asciicast) }

  describe '#to_json' do
    subject { JSON.parse(serializer.to_json) }

    it { should eq({ "id" => 1, "duration" => 11.146430015563965,
                     "stdout_frames_url" => nil, "snapshot" => nil,
                     "width" => 96, "height" => 26 }) }
  end

end
