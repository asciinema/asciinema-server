require 'spec_helper'

describe BrushPresenter do
  let(:brush_presenter) { BrushPresenter.new(brush) }
  let(:brush) { double('brush', :fg => nil, :bg => nil, :bold? => false,
                                :underline? => false, :inverse? => false) }

  describe '#to_css_class' do
    subject { brush_presenter.to_css_class }

    context "when brush is a default one" do
      before do
        allow(brush).to receive(:default?) { true }
      end

      it { should be(nil) }
    end

    context "when brush is not a default one" do
      before do
        allow(brush).to receive(:default?) { false }
      end

      context "when fg is default" do
        before do
          allow(brush).to receive(:fg) { nil }
        end

        it { should_not match(/\bfg/) }
      end

      context "when fg is non-default" do
        before do
          allow(brush).to receive(:fg) { 1 }
        end

        it { should match(/\bfg1\b/) }
      end

      context "when bg is default" do
        before do
          allow(brush).to receive(:bg) { nil }
        end

        it { should_not match(/\bbg/) }
      end

      context "when bg is non-default" do
        before do
          allow(brush).to receive(:bg) { 2 }
        end

        it { should match(/\bbg2\b/) }
      end

      context "when both fg and bg are non-default" do
        before do
          allow(brush).to receive(:fg) { 1 }
          allow(brush).to receive(:bg) { 2 }
        end

        it { should match(/\bfg1\b/) }
        it { should match(/\bbg2\b/) }
      end

      context "when it's bold" do
        before do
          allow(brush).to receive(:bold?) { true }
        end

        it { should match(/\bbold\b/) }
      end

      context "when it's underline" do
        before do
          allow(brush).to receive(:underline?) { true }
        end

        it { should match(/\bunderline\b/) }
      end

      context "when it's inverse" do
        before do
          allow(brush).to receive(:inverse?) { true }
        end

        it { should match(/\binverse\b/) }
      end
    end
  end
end
