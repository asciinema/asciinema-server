require 'spec_helper'

describe AsciicastCreator do

  let(:creator) { described_class.new }

  describe '#create' do
    let(:asciicast) { stub_model(Asciicast, id: 666) }
    let(:input_attrs) { { a: 'A' } }
    let(:headers) { { 'User-Agent' => 'asciinema/0.9.7' } }
    let(:prepared_attrs) { double('prepared_attrs', attributes: { b: 'B' }) }

    subject { creator.create(input_attrs, headers) }

    before do
      allow(AsciicastParams).to receive(:build).
        with(input_attrs, headers) { prepared_attrs }
      allow(Asciicast).to receive(:create!) { asciicast }
    end

    it 'calls Asciicast.create! with proper attributes' do
      subject

      expect(Asciicast).to have_received(:create!).
        with({ b: 'B' }, { without_protection: true })
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
