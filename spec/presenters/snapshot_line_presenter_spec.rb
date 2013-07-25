require 'spec_helper'

describe SnapshotLinePresenter do
  let(:snapshot_line_presenter) { SnapshotLinePresenter.new(snapshot_line) }
  let(:snapshot_line) { SnapshotLine.new([fragment_1, fragment_2]) }
  let(:fragment_1) { double('fragment_1') }
  let(:fragment_2) { double('fragment_2') }
  let(:fragment_1_presenter) { double(:to_html => '<fragment_1>') }
  let(:fragment_2_presenter) { double(:to_html => '<fragment_2>') }

  describe '#to_html' do
    subject { snapshot_line_presenter.to_html }

    before do
      allow(SnapshotFragmentPresenter).to receive(:new).with(fragment_1).
        and_return(fragment_1_presenter)
      allow(SnapshotFragmentPresenter).to receive(:new).with(fragment_2).
        and_return(fragment_2_presenter)
    end

    it { should be_kind_of(ActiveSupport::SafeBuffer) }
    it { should eq('<span class="line"><fragment_1><fragment_2></span>') }
  end
end
