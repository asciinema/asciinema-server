require 'rails_helper'

describe Grid do

  let(:grid) { described_class.new(data) }

  let(:data) { [
    %w[a b c ć],
    %w[de ff],
    %w[ghiî],
    %w[j k l m]
  ] }

  describe '#width' do
    let(:data) { [ %w[a bc def] ] }

    subject { grid.width }

    it { should eq(6) }
  end

  describe '#height' do
    subject { grid.height }

    it { should eq(4) }
  end

  describe '#crop' do
    let(:expected) { described_class.new([%w[e f], %w[hi], %w[k l]]).lines }

    it 'crops the lines properly' do
      expect(grid.crop(1, 1, 2, 3).lines).to eq(expected)
    end
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

    it { should eq([%w[a b c ć], %w[de ff], %w[ghiî], %w[j k l m]]) }
  end

end
