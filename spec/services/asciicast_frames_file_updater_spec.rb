require 'rails_helper'

describe AsciicastFramesFileUpdater do

  let(:updater) { described_class.new(file_writer) }
  let(:file_writer) { double('file_writer') }

  describe '#update', needs_terminal_bin: true do
    let(:asciicast) { create(:asciicast) }
    let(:film) { double('film', :frames => frames) }
    let(:frames) { [1, 2] }

    subject { updater.update(asciicast) }

    before do
      allow(Film).to receive(:new).with(asciicast.stdout, kind_of(Terminal)) {
        film
      }
      allow(file_writer).to receive(:write_enumerable) do |file, frames|
        file << frames.to_json
      end
    end

    it 'updates stdout_frames file on asciicast' do
      subject

      expect(asciicast.stdout_frames.read).to eq('[1,2]')
    end
  end

end
