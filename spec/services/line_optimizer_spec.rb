require 'spec_helper'

describe LineOptimizer do

  let(:line_optimizer) { described_class.new }

  def brush(attrs)
    Brush.new(attrs)
  end

  describe '#optimize' do
    let(:line) { [
      Cell.new('a', brush(fg: 1)),
      Cell.new('b', brush(fg: 1)),
      Cell.new('c', brush(fg: 2)),
      Cell.new('d', brush(fg: 3)),
      Cell.new('e', brush(fg: 3))
    ] }

    subject { line_optimizer.optimize(line) }

    it { should eq([
      Cell.new('ab', brush(fg: 1)),
      Cell.new('c',  brush(fg: 2)),
      Cell.new('de', brush(fg: 3))
    ]) }
  end

end
