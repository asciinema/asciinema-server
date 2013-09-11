require 'spec_helper'

describe SnapshotDecorator do

  let(:decorator) { described_class.new(snapshot) }
  let(:snapshot) { double('snapshot', :width => 2, :height => 2) }
  let(:optimizer) { double('optimizer') }
  let(:cells) { [
    [:a, :b],
    [:c, :d]
  ] }

  describe '#lines' do
    subject { decorator.lines }

    before do
      allow(snapshot).to receive(:cell) { |x, y| cells[y][x] }

      allow(LineOptimizer).to receive(:new) { optimizer }
      allow(optimizer).to receive(:optimize).with([:a, :b]) { [:ab] }
      allow(optimizer).to receive(:optimize).with([:c, :d]) { [:c, :d] }

      allow(CellDecorator).to receive(:new).with(:ab) { :AB }
      allow(CellDecorator).to receive(:new).with(:c) { :C }
      allow(CellDecorator).to receive(:new).with(:d) { :D }
    end

    it { should eq([ [:AB], [:C, :D] ]) }
  end

end
