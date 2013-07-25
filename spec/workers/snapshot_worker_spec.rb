require 'spec_helper'

describe SnapshotWorker do
  let(:worker) { SnapshotWorker.new }

  describe '#perform' do
    let(:snapshotter) { double('snapshotter', :run => nil) }

    it 'calls #run on AsciicastSnapshotter' do
      allow(AsciicastSnapshotter).to receive(:new).with(123) { snapshotter }

      worker.perform(123)

      expect(snapshotter).to have_received(:run).with(no_args())
    end
  end
end
