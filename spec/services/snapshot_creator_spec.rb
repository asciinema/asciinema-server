require 'spec_helper'

describe SnapshotCreator do

  let(:snapshot_creator) { SnapshotCreator.new }

  describe '#create' do
    let(:stdout) { double('stdout', :bytes_until => []) }
    let(:terminal) { double('terminal', :feed => snapshot) }
    let(:snapshot) { double('snapshot') }

    subject { snapshot_creator.create(80, 24, stdout, 31.4) }

    before do
      allow(Terminal).to receive(:new).with(80, 24) { terminal }
      allow(stdout).to receive(:bytes_until) { [1, 2, 3] }
    end

    it 'uses Terminal to generate a snapshot' do
      subject

      expect(terminal).to have_received(:feed).with([1, 2, 3])
    end

    it 'gets the bytes from stdout for half duration (whole seconds)' do
      subject

      expect(stdout).to have_received(:bytes_until).with(15)
    end

    it 'returns the snapshot from the Terminal' do
      expect(subject).to be(snapshot)
    end
  end

end
