require 'rails_helper'

describe AsciicastWorker do

  let(:worker) { described_class.new }

  describe '#perform' do
    let(:asciicast) { double('asciicast') }
    let(:asciicast_processor) { double('asciicast_processor', :process => nil) }

    before do
      allow(Asciicast).to receive(:find).with(123) { asciicast }
      allow(AsciicastProcessor).to receive(:new).
        with(no_args) { asciicast_processor }
    end

    it 'processes given asciicast with AsciicastProcessor' do
      worker.perform(123)

      expect(asciicast_processor).to have_received(:process).with(asciicast)
    end
  end

end
