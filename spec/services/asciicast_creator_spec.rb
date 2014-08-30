require 'rails_helper'

describe AsciicastCreator do

  let(:creator) { described_class.new }

  describe '#create' do
    subject { creator.create(attributes) }

    let(:attributes) { { a: 'A' } }
    let(:asciicast) { stub_model(Asciicast, id: 666) }

    before do
      allow(Asciicast).to receive(:create!) { asciicast }
    end

    it 'calls Asciicast.create! with proper attributes' do
      subject

      expect(Asciicast).to have_received(:create!).with(attributes)
    end

    it 'enqueues a post-processing job' do
      subject

      expect(AsciicastWorker).to have_queued_job(666)
    end

    it 'returns the created asciicast' do
      expect(subject).to be(asciicast)
    end
  end

end
