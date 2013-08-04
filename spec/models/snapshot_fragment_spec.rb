require 'spec_helper'

describe SnapshotFragment do

  describe '#==' do
    let(:snapshot_fragment) { SnapshotFragment.new('foo', brush_1) }
    let(:brush_1) { double('brush_1') }
    let(:brush_2) { double('brush_2') }

    subject { snapshot_fragment == other }

    context "when fragments have the same texts and brushes" do
      let(:other) { SnapshotFragment.new('foo', brush_1) }

      it { should be(true) }
    end

    context "when fragments have different texts" do
      let(:other) { SnapshotFragment.new('bar', brush_1) }

      it { should be(false) }
    end

    context "when fragments have different brushes" do
      let(:other) { SnapshotFragment.new('foo', brush_2) }

      it { should be(false) }
    end
  end

  describe '#crop' do
    let(:snapshot_fragment) { SnapshotFragment.new('foobar', brush) }
    let(:brush) { double('brush') }

    context "when size is smaller than fragment's size" do
      subject { snapshot_fragment.crop(3) }

      it 'returns a new instance of SnapshotFragment' do
        expect(subject).to be_kind_of(SnapshotFragment)
        expect(subject).to_not be(snapshot_fragment)
      end

      it 'trims the text to the requested size' do
        expect(subject.text).to eq('foo')
      end

      it 'returns SnapshotFragment with the same brush' do
        expect(subject.brush).to be(brush)
      end
    end

    context "when size is equal or larger than the fragment's size" do
      it 'returns self' do
        expect(snapshot_fragment.crop(6)).to be(snapshot_fragment)
      end
    end
  end

  describe '#size' do
    let(:snapshot_fragment) { SnapshotFragment.new('f' * 100, Brush.new) }

    subject { snapshot_fragment.size }

    it { should eq(100) }
  end

end
