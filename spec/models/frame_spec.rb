require 'rails_helper'

describe Frame do

  let(:frame) { described_class.new(snapshot, cursor) }
  let(:snapshot) { double('snapshot', :diff => snapshot_diff) }
  let(:cursor) { double('cursor', :diff => cursor_diff) }
  let(:snapshot_diff) { double('snapshot_diff') }
  let(:cursor_diff) { double('cursor_diff') }

  describe '#diff' do
    let(:other) { double('other', :snapshot => other_snapshot,
                                  :cursor => other_cursor) }
    let(:other_snapshot) { double('other_snapshot') }
    let(:other_cursor) { double('other_cursor') }
    let(:frame_diff) { double('frame_diff') }

    subject { frame.diff(other) }

    before do
      allow(FrameDiff).to receive(:new).
        with(snapshot_diff, cursor_diff) { frame_diff }
    end

    it 'returns a FrameDiff instance built from snapshot and cursor diffs' do
      expect(subject).to be(frame_diff)
    end

    context "when other is nil" do
      let(:other) { nil }

      it 'diffs its snapshot with nil' do
        subject

        expect(snapshot).to have_received(:diff).with(nil)
      end

      it 'diffs its cursor with nil' do
        subject

        expect(cursor).to have_received(:diff).with(nil)
      end
    end
  end

end
