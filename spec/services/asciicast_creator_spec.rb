require 'spec_helper'

describe AsciicastCreator do
  let(:creator) { AsciicastCreator.new }

  describe '#create' do
    let(:meta_file) { fixture_file_upload('spec/fixtures/meta.json', 'application/json') }
    let(:stdout_data_file) { double('stdout_data_file') }
    let(:stdout_timing_file) { double('stdout_timing_file') }
    let(:asciicast) { stub_model(Asciicast, :id => 666) }

    subject {
      creator.create(
        :meta          => meta_file,
        :stdout        => stdout_data_file,
        :stdout_timing => stdout_timing_file
      )
    }

    before do
      allow(Asciicast).to receive(:create!) { asciicast }
    end

    it 'calls Asciicast.create! with proper attributes' do
      subject

      expect(Asciicast).to have_received(:create!).with({
        :stdout_data      => stdout_data_file,
        :stdout_timing    => stdout_timing_file,
        :stdin_data       => nil,
        :stdin_timing     => nil,
        :username         => 'kill',
        :user_token       => 'f33e6188-f53c-11e2-abf4-84a6c827e88b',
        :duration         => 11.146430015563965,
        :recorded_at      => 'Thu, 25 Jul 2013 20:08:57 +0000',
        :title            => 'bashing :)',
        :command          => '/bin/bash',
        :shell            => '/bin/zsh',
        :uname            => 'Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64',
        :terminal_columns => 96,
        :terminal_lines   => 26,
        :terminal_type    => 'screen-256color'
      }, { :without_protection => true })
    end

    it 'enqueues snapshot capture job' do
      subject

      expect(SnapshotWorker).to have_queued_job(asciicast.id)
    end

    it 'returns the created asciicast' do
      expect(subject).to be(asciicast)
    end
  end
end
