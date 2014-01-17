require 'spec_helper'

describe HomePresenter do

  let(:presenter) { described_class.new }

  describe '#asciicast' do
    subject { presenter.asciicast }

    before do
      allow(CFG).to receive(:home_asciicast) { home_asciicast }
    end

    context "when home_asciicast is present" do
      let(:home_asciicast) { stub_model(Asciicast, id: 123) }

      it "returns decorated asciicast" do
        expect(subject.title).to eq("asciicast:123")
      end
    end

    context "when home_asciicast isn't present" do
      let(:home_asciicast) { nil }

      it { should be(nil) }
    end
  end

  describe '#latest_asciicasts' do
    subject { presenter.latest_asciicasts }

    let(:asciicast) { stub_model(Asciicast, id: 123) }

    before do
      allow(Asciicast).to receive(:latest_limited) { [asciicast] }
    end

    it "returns decorated latest asciicasts" do
      expect(subject.first.title).to eq("asciicast:123")
    end
  end

  describe '#featured_asciicasts' do
    subject { presenter.featured_asciicasts }

    let(:asciicast) { stub_model(Asciicast, id: 123) }

    before do
      allow(Asciicast).to receive(:random_featured_limited) { [asciicast] }
    end

    it "returns decorated random featured asciicasts" do
      expect(subject.first.title).to eq("asciicast:123")
    end
  end

end
