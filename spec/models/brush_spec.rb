require 'spec_helper'

describe Brush do
  let(:brush) { Brush.new(attributes) }

  describe '#==' do
    let(:attributes) { {
      :fg        => 1,
      :bg        => 2,
      :bold      => true,
      :underline => false,
      :inverse   => true,
      :blink     => false,
      :foo       => true,
    } }

    subject { brush == other }

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
    subject { brush.fg }

    context "when fg was set" do
      let(:attributes) { { :fg => 1 } }

      it { should eq(1) }
    end

    context "when fg was not set" do
      let(:attributes) { {} }

      it { should be(nil) }
    end

    context "when bold is set" do
      let(:attributes) { { :bold => true } }

      context "and input fg is < 8" do
        before do
          attributes[:fg] = 7
        end

        it { should eq(15) }
      end

      context "and input fg is == 8" do
        before do
          attributes[:fg] = 8
        end

        it { should eq(8) }
      end

      context "and input fg is > 8" do
        before do
          attributes[:fg] = 9
        end

        it { should eq(9) }
      end
    end
  end

  describe '#bg' do
    subject { brush.bg }

    context "when bg was set" do
      let(:attributes) { { :bg => 2 } }

      it { should eq(2) }
    end

    context "when bg was not set" do
      let(:attributes) { {} }

      it { should be(nil) }
    end

    context "when blink is set" do
      let(:attributes) { { :blink => true } }

      context "and input bg is < 8" do
        before do
          attributes[:bg] = 7
        end

        it { should eq(15) }
      end

      context "and input bg is == 8" do
        before do
          attributes[:bg] = 8
        end

        it { should eq(8) }
      end

      context "and input bg is > 8" do
        before do
          attributes[:bg] = 9
        end

        it { should eq(9) }
      end
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
