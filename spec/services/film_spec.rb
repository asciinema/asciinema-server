require 'spec_helper'

describe Film do

  let(:film) { described_class.new(stdout, terminal) }
  let(:terminal) { FakeTerminal.new }

  describe '#snapshot_at' do
    let(:stdout) { [[0.5, 'ab'], [1.0, 'cd'], [2.0, 'ef']] }

    subject { film.snapshot_at(1.7) }

    it "returns the snapshot of the terminal" do
      expect(subject).to eq('abcd')
    end
  end

  describe '#frames' do
    let(:stdout) { [[0.5, 'ab'], [1.0, 'cd']] }
    let(:frame_1) { double('frame_1') }
    let(:frame_2) { double('frame_2') }
    let(:frame_diff_list) { double('frame_diff_list') }

    subject { film.frames }

    before do
      allow(Frame).to receive(:new).with('ab', 2) { frame_1 }
      allow(Frame).to receive(:new).with('abcd', 4) { frame_2 }
      allow(FrameDiffList).to receive(:new).
        with([[0.5, frame_1], [1.0, frame_2]]) { frame_diff_list }
    end

    it 'returns delay and frame tuples wrapped with FrameDiffList' do
      expect(subject).to be(frame_diff_list)
    end
  end

end
