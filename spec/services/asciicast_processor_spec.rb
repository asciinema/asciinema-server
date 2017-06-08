require 'rails_helper'

describe AsciicastProcessor do

  let(:processor) { described_class.new }

  describe '#process' do
    let(:asciicast) { double('asciicast', version: 0) }
    let(:snapshot_updater) { double('snapshot_updater', :update => nil) }
    let(:frames_file_updater) { double('frames_file_updater', :update => nil) }

    subject { processor.process(asciicast) }

    before do
      allow(AsciicastSnapshotUpdater).to receive(:new) { snapshot_updater }
      allow(AsciicastFramesFileUpdater).to receive(:new) { frames_file_updater }
    end

    it 'generates a snapshot' do
      subject

      expect(snapshot_updater).to have_received(:update).with(asciicast)
    end

    it 'generates animation frames' do
      subject

      expect(frames_file_updater).to have_received(:update).with(asciicast)
    end
  end

end
