require 'spec_helper'

describe Brush do
  let(:brush) { Brush.new(attributes) }

  describe '#==' do
    subject { brush == other }

    let(:attributes) { {
      :fg        => 1,
      :bg        => 2,
      :bold      => true,
      :underline => false,
      :inverse   => true,
      :blink     => false,
      :foo       => true,
    } }

    context "when all fg, bg, bold?, underline? and inverse? are equal" do
      let(:other) { Brush.new(
        :fg        => 1,
        :bg        => 2,
        :bold      => true,
        :underline => false,
        :inverse   => true,
        :blink     => false,
        :foo       => false # should be ignored
      ) }

      it { should be(true) }
    end

    context "when fg, bg, bold?, underline? and inverse? are not equal" do
      let(:other) { Brush.new(
        :fg        => 1,
        :bg        => 2,
        :bold      => false,
        :underline => false,
        :inverse   => true,
        :blink     => false,
        :foo       => true # should be ignored
      ) }

      it { should be(false) }
    end
  end

  describe '#fg' do
    it 'behaves like in rxvt/gnome-terminal' do
      expect(Brush.new.fg).to eq(nil)
      expect(Brush.new(fg: 1).fg).to eq(1)
      expect(Brush.new(fg: 1, bold: true).fg).to eq(9)
      expect(Brush.new(fg: 8, bold: true).fg).to eq(8)
      expect(Brush.new(fg: 9, bold: true).fg).to eq(9)
      expect(Brush.new(fg: 1, inverse: true).fg).to eq(0)
      expect(Brush.new(bg: 2, inverse: true).fg).to eq(2)
      expect(Brush.new(fg: 1, inverse: true, blink: true).fg).to eq(0)
      expect(Brush.new(bg: 1, inverse: true, blink: true).fg).to eq(9)
      expect(Brush.new(bg: 0, inverse: true).fg).to eq(0)
      expect(Brush.new(bg: 0, inverse: true, blink: true).fg).to eq(8)
      expect(Brush.new(inverse: true, blink: true).fg).to eq(0)
    end
  end

  describe '#bg' do
    it 'behaves like in rxvt/gnome-terminal' do
      expect(Brush.new.bg).to eq(nil)
      expect(Brush.new(bg: 1).bg).to eq(1)
      expect(Brush.new(bg: 1, blink: true).bg).to eq(9)
      expect(Brush.new(bg: 8, blink: true).bg).to eq(8)
      expect(Brush.new(bg: 9, blink: true).bg).to eq(9)
      expect(Brush.new(bg: 1, inverse: true).bg).to eq(7)
      expect(Brush.new(fg: 2, inverse: true).bg).to eq(2)
      expect(Brush.new(bg: 1, inverse: true, bold: true).bg).to eq(7)
      expect(Brush.new(fg: 1, inverse: true, bold: true).bg).to eq(9)
      expect(Brush.new(fg: 0, inverse: true).bg).to eq(0)
      expect(Brush.new(fg: 0, inverse: true, bold: true).bg).to eq(8)
      expect(Brush.new(inverse: true, bold: true).bg).to eq(7)
    end
  end

  describe '#bold?' do
    subject { brush.bold? }

    context "when bold was set to true" do
      let(:attributes) { { :bold => true } }

      it { should be(true) }
    end

    context "when bold was set to false" do
      let(:attributes) { { :bold => false } }

      it { should be(false) }
    end

    context "when bold was not set" do
      let(:attributes) { {} }

      it { should be(false) }
    end
  end

  describe '#underline?' do
    subject { brush.underline? }

    context "when underline was set to true" do
      let(:attributes) { { :underline => true } }

      it { should be(true) }
    end

    context "when underline was set to false" do
      let(:attributes) { { :underline => false } }

      it { should be(false) }
    end

    context "when underline was not set" do
      let(:attributes) { {} }

      it { should be(false) }
    end
  end

  describe '#inverse?' do
    subject { brush.inverse? }

    context "when inverse was set to true" do
      let(:attributes) { { :inverse => true } }

      it { should be(true) }
    end

    context "when inverse was set to false" do
      let(:attributes) { { :inverse => false } }

      it { should be(false) }
    end

    context "when inverse was not set" do
      let(:attributes) { {} }

      it { should be(false) }
    end
  end

  describe '#blink?' do
    subject { brush.blink? }

    context "when blink was set to true" do
      let(:attributes) { { :blink => true } }

      it { should be(true) }
    end

    context "when blink was set to false" do
      let(:attributes) { { :blink => false } }

      it { should be(false) }
    end

    context "when blink was not set" do
      let(:attributes) { {} }

      it { should be(false) }
    end
  end

  describe '#default?' do
    subject { brush.default? }

    context "when all attributes are falsy" do
      let(:attributes) { {} }

      it { should be(true) }
    end

    context "when fg is set" do
      let(:attributes) { { :fg => 1 } }

      it { should be(false) }
    end

    context "when bg is set" do
      let(:attributes) { { :bg => 2 } }

      it { should be(false) }
    end

    context "when bold is set" do
      let(:attributes) { { :bold => true } }

      it { should be(false) }
    end

    context "when underline is set" do
      let(:attributes) { { :underline => true } }

      it { should be(false) }
    end

    context "when inverse is set" do
      let(:attributes) { { :inverse => true } }

      it { should be(false) }
    end

    context "when blink is set" do
      let(:attributes) { { :blink => true } }

      it { should be(false) }
    end
  end

  describe '#as_json' do
    let(:attributes) { { fg: 1, bold: true, trolololo: 'OX' } }

    subject { brush.as_json }

    it { should eq({ fg: 1, bold: true }) }
  end

end
