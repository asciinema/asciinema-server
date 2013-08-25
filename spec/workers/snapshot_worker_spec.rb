require 'spec_helper'

describe SnapshotWorker do

  let(:worker) { SnapshotWorker.new }

  describe '#perform' do
    let(:snapshot_creator) { double('snapshot_creator', :create => snapshot) }
    let(:snapshot) { double('snapshot') }
    let(:asciicast) { double('asciicast', :terminal_columns => 9,
                                          :terminal_lines   => 5,
                                          :duration         => 4.3,
                                          :stdout           => stdout,
                                          :update_snapshot  => nil) }
    let(:stdout) { double('stdout') }

    before do
      allow(Asciicast).to receive(:find).with(123) { asciicast }
      allow(SnapshotCreator).to receive(:new).with(no_args) { snapshot_creator }
    end

    it 'uses AsciicastSnapshotCreator to generate a snapshot' do
      worker.perform(123)

      expect(snapshot_creator).to have_received(:create).with(9, 5, stdout, 4.3)
    end

    it 'updates the snapshot on the asciicast' do
      worker.perform(123)

      expect(asciicast).to have_received(:update_snapshot).with(snapshot)
    end
  end

end
