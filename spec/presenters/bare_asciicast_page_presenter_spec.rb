require 'rails_helper'

describe BareAsciicastPagePresenter do

  describe '.build' do
    subject { described_class.build(asciicast, playback_options) }

    let(:asciicast) { stub_model(Asciicast, decorate: decorated_asciicast) }
    let(:playback_options) { { speed: 3.0 } }
    let(:decorated_asciicast) { double('decorated_asciicast', theme_name: 'foo') }

    it "builds presenter with given asciicast decorated" do
      expect(subject.asciicast).to be(decorated_asciicast)
    end

    it "builds presenter with given playback options" do
      expect(subject.playback_options.speed).to eq(3.0)
      expect(subject.playback_options.theme).to eq('foo')
    end
  end

  let(:presenter) { described_class.new(asciicast, nil) }
  let(:asciicast) { stub_model(Asciicast, id: 123) }

  describe '#asciicast_id' do
    subject { presenter.asciicast_id }

    it { should eq('123') }
  end

end
