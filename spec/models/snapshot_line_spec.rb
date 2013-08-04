require 'spec_helper'

describe SnapshotLine do

  describe '.build' do
    let(:line) { SnapshotLine.build(input) }
    let(:input) { [input_fragment_1, input_fragment_2] }
    let(:input_fragment_1) { ['foo', { :fg => 1, :bold => true }] }
    let(:input_fragment_2) { ['bar', { :bg => 2 }] }

    it 'returns an instance of SnapshotLine' do
      expect(line).to be_kind_of(SnapshotLine)
    end

    it 'returns properly joined fragments' do
      fragment_1 = line.to_a[0]
      fragment_2 = line.to_a[1]

      expect(fragment_1.text).to eq('foo')
      expect(fragment_1.brush).to eq(Brush.new(:fg => 1, :bold => true))
      expect(fragment_2.text).to eq('bar')
      expect(fragment_2.brush).to eq(Brush.new(:bg => 2))
    end
  end

  describe '#each' do
    let(:snapshot_line) { SnapshotLine.new([:fragment_1, :fragment_2]) }

    it 'yields to the given block for each fragment' do
      fragments = []

      snapshot_line.each do |fragment|
        fragments << fragment
      end

      expect(fragments).to eq([:fragment_1, :fragment_2])
    end
  end

  describe '#==' do
    let(:snapshot_line) { SnapshotLine.new([:foo]) }

    subject { snapshot_line == other }

    context "when lines have the same fragments" do
      let(:other) { SnapshotLine.new([:foo]) }

      it { should be(true) }
    end

    context "when lines have different fragments" do
      let(:other) { SnapshotLine.new([:foo, :bar]) }

      it { should be(false) }
    end
  end

  describe '#crop' do
    let(:snapshot_line) { SnapshotLine.new(fragments) }
    let(:fragments) { [fragment_1, fragment_2] }
    let(:fragment_1) { double('fragment_1', :size => 2, :crop => nil) }
    let(:fragment_2) { double('fragment_2', :size => 3,
                                            :crop => cropped_fragment_2) }
    let(:fragment_3) { double('fragment_3', :size => 4, :crop => nil) }
    let(:cropped_fragment_2) { double('cropped_fragment_2', :size => 2) }

    context "when cropping point is at the end of the first fragment" do
      it 'crops none of the fragments' do
        snapshot_line.crop(2)

        expect(fragment_1).to_not have_received(:crop)
        expect(fragment_2).to_not have_received(:crop)
        expect(fragment_3).to_not have_received(:crop)
      end

      it 'returns a new SnapshotLine with only the first fragment' do
        expect(snapshot_line.crop(2)).to eq(SnapshotLine.new([fragment_1]))
      end
    end

    context "when cropping point is inside of the second fragment" do
      it 'crops only the second fragment' do
        snapshot_line.crop(4)

        expect(fragment_1).to_not have_received(:crop)
        expect(fragment_2).to have_received(:crop).with(2)
        expect(fragment_3).to_not have_received(:crop)
      end

      it 'returns a new SnapshotLine with first two fragments cropped' do
        expect(snapshot_line.crop(4)).
          to eq(SnapshotLine.new([fragment_1, cropped_fragment_2]))
      end
    end
  end

end
