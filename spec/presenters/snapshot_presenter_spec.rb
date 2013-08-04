require 'spec_helper'

describe SnapshotPresenter do
  let(:snapshot_presenter) { SnapshotPresenter.new(snapshot) }
  let(:snapshot) { Snapshot.new([line_1, line_2]) }
  let(:line_1) { double('line_1') }
  let(:line_2) { double('line_2') }
  let(:line_1_presenter) { double(:to_html => '<line_1>') }
  let(:line_2_presenter) { double(:to_html => '<line_2>') }

  describe '#to_html' do
    subject { snapshot_presenter.to_html }

    before do
      allow(SnapshotLinePresenter).to receive(:new).with(line_1).
        and_return(line_1_presenter)
      allow(SnapshotLinePresenter).to receive(:new).with(line_2).
        and_return(line_2_presenter)
    end

    it { should be_kind_of(ActiveSupport::SafeBuffer) }
    it { should eq(%(<pre class="terminal"><line_1>\n<line_2>\n</pre>)) }
  end
end
