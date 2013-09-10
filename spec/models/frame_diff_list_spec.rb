require 'spec_helper'

describe FrameDiffList do

  let(:frame_diff_list) { described_class.new(frames) }
  let(:frames) { [[1.5, frame_1], [0.5, frame_2]] }
  let(:frame_1) { double('frame_1', :diff => diff_1) }
  let(:frame_2) { double('frame_2', :diff => diff_2) }
  let(:diff_1) { double('diff_1') }
  let(:diff_2) { double('diff_2') }

  describe '#each' do
    subject { frame_diff_list.to_a }

    it 'maps each frame to its diff' do
      expect(subject).to eq([[1.5, diff_1], [0.5, diff_2]])
    end

    it 'diffs the first frame with nil' do
      subject

      expect(frame_1).to have_received(:diff).with(nil)
    end

    it 'diffs the subsequent frames with the previous ones' do
      subject

      expect(frame_2).to have_received(:diff).with(frame_1)
    end
  end

end
