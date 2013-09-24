require 'spec_helper'

describe CellDecorator do

  let(:decorator) { described_class.new(cell) }
  let(:cell) { double('cell', :brush => brush) }
  let(:brush) { double('brush') }

  describe '#css_class' do
    let(:brush_presenter) { double('brush_presenter', :css_class => 'kls') }

    subject { decorator.css_class }

    before do
      allow(BrushDecorator).to receive(:new).with(brush) { brush_presenter }
    end

    it { should eq('kls') }
  end

end
