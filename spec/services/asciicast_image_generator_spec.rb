require 'rails_helper'

describe AsciicastImageGenerator, needs_phantomjs_2_bin: true do

  let(:image_generator) { AsciicastImageGenerator.new(template_renderer) }
  let(:template_renderer) { ApplicationController.new }

  describe '#generate' do
    let(:asciicast) { create(:asciicast, theme_name: 'tango') }

    def rgb(color)
      [ChunkyPNG::Color.r(color), ChunkyPNG::Color.g(color), ChunkyPNG::Color.b(color)]
    end

    before do
      image_generator.generate(asciicast)
    end

    it 'generates screenshot of "snapshot frame"' do
      png = ChunkyPNG::Image.from_file(asciicast.image.path)

      # make sure there are black-ish borders
      expect(rgb(png[1, 1])).to eq([18, 19, 20])
      expect(rgb(png[png.width - 2, png.height - 2])).to eq([18, 19, 20])

      # check content color (blue background)
      expect(rgb(png[15, 15])).to eq([0, 175, 255])

      # make sure white SVG play icon is rendered correctly
      expect(rgb(png[png.width / 2, (png.height / 2) - 10])).to eq([255, 255, 255])

      # make sure PowerlineSymbols are rendered
      expect(rgb(png[144, 795])).to eq([0, 95, 255])
    end

    it 'sets image_width and image_height on the asciicast' do
      expect(asciicast.image_width).to_not be(nil)
      expect(asciicast.image_height).to_not be(nil)
    end
  end

end
