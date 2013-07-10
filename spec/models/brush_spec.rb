require 'spec_helper'

describe Brush do
  let(:brush) { Brush.new(attributes) }

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

end
