require 'spec_helper'

describe AsciicastSnapshotUpdater do

  let(:updater) { described_class.new }

  describe '#update' do
    let(:asciicast) { double('asciicast', :duration => 5.0, :stdout => stdout,
                                          :update_attribute => nil) }
    let(:stdout) { double('stdout') }
    let(:terminal) { double('terminal') }
    let(:film) { double('film', :snapshot_at => 'foo') }

    subject { updater.update(asciicast) }

    before do
      allow(asciicast).to receive(:with_terminal).and_yield(terminal)
      allow(Film).to receive(:new).with(stdout, terminal) { film }

      subject
    end

    it "generates the snapshot at half of asciicast's duration" do
      expect(film).to have_received(:snapshot_at).with(2.5)
    end

    it "updates asciicast's snapshot to the terminal's snapshot" do
      expect(asciicast).to have_received(:update_attribute).
        with(:snapshot, 'foo')
    end

    context "when snapshot time given" do
      subject { updater.update(asciicast, 4.3) }

      it "generates the snapshot at the given time" do
        expect(film).to have_received(:snapshot_at).with(4.3)
      end
    end
  end

end
