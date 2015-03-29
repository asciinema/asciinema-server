require 'rails_helper'

describe ImageInspector do

  let(:image_inspector) { ImageInspector.new }

  describe '#get_size' do
    it 'returns width and height of the image' do
      w, h = image_inspector.get_size("#{Rails.root}/spec/fixtures/new-logo-bars.png")

      expect(w).to eq(154)
      expect(h).to eq(33)
    end

    context 'when file is not an image' do
      it 'raises error' do
        expect { image_inspector.get_size("#{Rails.root}/spec/fixtures/snapshot.json") }.to raise_error(RuntimeError)
      end
    end
  end

end
