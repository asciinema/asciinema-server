require 'spec_helper'

describe SnapshotDecorator do

  let(:decorator) { described_class.new(snapshot) }
  let(:snapshot) { double('snapshot', width: 2, height: 2, lines: lines) }
  let(:lines) { [ [:ab], [:c, :d] ] }

  describe '#lines' do
    subject { decorator.lines }

    before do
      allow(CellDecorator).to receive(:new).with(:ab) { :AB }
      allow(CellDecorator).to receive(:new).with(:c) { :C }
      allow(CellDecorator).to receive(:new).with(:d) { :D }
    end

    it { should eq([ [:AB], [:C, :D] ]) }
  end

end
