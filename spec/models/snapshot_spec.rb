require 'spec_helper'

describe Snapshot do

  let(:snapshot) { described_class.new(grid) }
  let(:grid) { double('grid', :width => 10, :height => 5,
                              :trailing_empty_lines => 2) }

  describe '#width' do
    subject { snapshot.width }

    it { should eq(10) }
  end

  describe '#height' do
    subject { snapshot.height }

    it { should eq(5) }
  end

  describe '#cell' do
    subject { snapshot.cell(1, 2) }

    before do
      allow(grid).to receive(:cell).with(1, 2) { :a }
    end

    it { should eq(:a) }
  end

  describe '#thumbnail' do
    let(:thumbnail) { snapshot.thumbnail(2, 4) }

    before do
      allow(grid).to receive(:crop) { Grid.new([[:a, :b], [:c, :d],
                                                [:e, :f], [:g, :h]]) }
    end

    it 'returns a thumbnail of requested width' do
      expect(thumbnail.width).to eq(2)
    end

    it 'returns a thumbnail of requested height' do
      expect(thumbnail.height).to eq(4)
    end

    it 'crops the grid at the bottom left corner' do
      thumbnail

      expect(grid).to have_received(:crop).with(0, 0, 2, 4)
    end
  end

end
