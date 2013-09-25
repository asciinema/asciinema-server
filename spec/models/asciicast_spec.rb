require 'spec_helper'
require 'tempfile'

describe Asciicast do

  let(:asciicast) { described_class.new }

  describe '#stdout' do
    let(:asciicast) { Asciicast.new }
    let(:data_uploader) { double('data_uploader',
                                 :decompressed_path => '/foo') }
    let(:timing_uploader) { double('timing_uploader',
                                   :decompressed_path => '/bar') }
    let(:stdout) { double('stdout', :lazy => lazy_stdout) }
    let(:lazy_stdout) { double('lazy_stdout') }

    subject { asciicast.stdout }

    before do
      allow(BufferedStdout).to receive(:new) { stdout }
      allow(StdoutDataUploader).to receive(:new) { data_uploader }
      allow(StdoutTimingUploader).to receive(:new) { timing_uploader }
    end

    it 'creates a new BufferedStdout instance' do
      subject

      expect(BufferedStdout).to have_received(:new).with('/foo', '/bar')
    end

    it 'returns lazy instance of stdout' do
      expect(subject).to be(lazy_stdout)
    end
  end

end
