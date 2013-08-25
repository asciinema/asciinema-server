require 'spec_helper'

describe SnapshotFragmentPresenter do
  let(:snapshot_fragment_presenter) { described_class.new(snapshot_fragment) }
  let(:snapshot_fragment) { SnapshotFragment.new('foo > bar', brush) }
  let(:brush) { double('brush') }
  let(:brush_presenter) { double('presenter', :to_css_class => css_class) }
  let(:css_class) { 'qux' }

  describe '#to_html' do
    subject { snapshot_fragment_presenter.to_html }

    before do
      allow(BrushPresenter).to receive(:new).with(brush).
        and_return(brush_presenter)
    end

    it { should be_kind_of(ActiveSupport::SafeBuffer) }
    it { should eq('<span class="qux">foo &gt; bar</span>') }

    context "when css class is nil" do
      let(:css_class) { nil }

      it { should eq('<span>foo &gt; bar</span>') }
    end
  end
end
