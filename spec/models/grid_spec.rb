require 'spec_helper'

describe Grid do

  let(:grid) { described_class.new(data) }

  let(:data) { [
    [:a, :b, :c],
    [:d, :e, :f],
    [:g, :h, :i],
    [:j, :k, :l]
  ] }

  describe '#==' do
    let(:grid) { described_class.new(grid_lines) }
    let(:other) { described_class.new(other_lines) }

    subject { grid == other }

    context "when lines are equal" do
      let(:grid_lines) { [:a] }
      let(:other_lines) { [:a] }

      it { should be(true) }
    end

    context "when lines are different" do
      let(:grid_lines) { [:a] }
      let(:other_lines) { [:b] }

      it { should be(false) }
    end
  end

  describe '#width' do
    subject { grid.width }

    it { should eq(3) }
  end

  describe '#height' do
    subject { grid.height }

    it { should eq(4) }
  end

  describe '#cell' do
    it 'returns item at given x and y position' do
      expect(grid.cell(0, 0)).to eq(:a)
      expect(grid.cell(1, 2)).to eq(:h)
      expect(grid.cell(2, 3)).to eq(:l)
    end
  end

  describe '#crop' do
    subject { grid.crop(1, 0, 2, 3) }

    it { should eq(described_class.new([[:b, :c], [:e, :f], [:h, :i]])) }
  end

  describe '#diff' do
    let(:line_a) { [:a, :b, :c] }
    let(:line_b) { [:d, :e, :f] }
    let(:line_c) { [:g, :h, :i] }

    let(:grid) { described_class.new([line_a, line_b, line_c]) }

    let(:line_d) { [:A, :b, :c] }
    let(:line_e) { [:g, :H, :i] }

    let(:other) { described_class.new([line_d, line_b, line_e]) }

    subject { grid.diff(other) }

    it 'returns only the lines that have changed from the other grid' do
      should eq({ 0 => line_a, 2 => line_c })
    end

    context "when other is nil" do
      let(:other) { nil }

      it 'returns all the lines' do
        should eq({ 0 => line_a, 1 => line_b, 2 => line_c })
      end
    end
  end

  describe '#as_json' do
    subject { grid.as_json }

    it { should eq([%w[a b c], %w[d e f], %w[g h i], %w[j k l]]) }
  end

end
