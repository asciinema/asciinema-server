require 'spec_helper'

describe Cell do

  let(:cell) { described_class.new('a', brush) }
  let(:brush) { double('brush') }

  describe '#empty?' do
    let(:cell) { described_class.new(text, brush) }

    subject { cell.empty? }

    context "when text is not blank" do
      let(:text) { 'a' }
      let(:brush) { double('brush', :default? => true) }

      it { should be(false) }
    end

    context "when brush is not default" do
      let(:text) { ' ' }
      let(:brush) { double('brush', :default? => false) }

      it { should be(false) }
    end

    context "when text is blank and brush is default" do
      let(:text) { ' ' }
      let(:brush) { double('brush', :default? => true) }

      it { should be(true) }
    end
  end

  describe '#==' do
    let(:other) { described_class.new(text, other_brush) }

    subject { cell == other }

    context "when text differs" do
      let(:text) { 'b' }
      let(:other_brush) { double('brush', :== => true) }

      it { should be(false) }
    end

    context "when brush differs" do
      let(:text) { 'a' }
      let(:other_brush) { double('brush', :== => false) }

      it { should be(false) }
    end

    context "when text and brush are equal" do
      let(:text) { 'a' }
      let(:other_brush) { double('brush', :== => true) }

      it { should be(true) }
    end
  end

  describe '#css_class' do
    let(:brush_presenter) { double('brush_presenter', :to_css_class => 'kls') }

    subject { cell.css_class }

    before do
      allow(BrushPresenter).to receive(:new).with(brush) { brush_presenter }
    end

    it { should eq('kls') }
  end

end
