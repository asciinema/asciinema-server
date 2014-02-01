require 'spec_helper'

describe BareAsciicastPagePresenter do
  
  describe '.build' do
    subject { described_class.build(asciicast, playback_options) }

    let(:asciicast) { stub_model(Asciicast, decorate: decorated_asciicast) }
    let(:playback_options) { { speed: 3.0 } }
    let(:decorated_asciicast) { double('decorated_asciicast') }

    it "builds presenter instance with given asciicast decorated" do
      expect(subject.asciicast).to be(decorated_asciicast)
    end

    it "builds presenter instance with given playback options" do
      expect(subject.playback_options.speed).to eq(3.0)
    end
  end

  let(:presenter) { described_class.new(asciicast, nil) }
  let(:asciicast) { stub_model(Asciicast, id: 123) }

  describe '#asciicast_id' do
    subject { presenter.asciicast_id }

    it { should eq(123) }
  end

end
