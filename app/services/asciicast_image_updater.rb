class AsciicastImageUpdater

  attr_reader :png_generator

  def initialize(png_generator = PngGenerator.new)
    @png_generator = png_generator
  end

  def update(asciicast, page_path)
    Dir.mktmpdir do |dir|
      png_path = "#{dir}/#{asciicast.image_filename}"

      png_generator.generate(page_path, png_path)

      File.open(png_path) do |f|
        asciicast.image = f
      end

      image = ChunkyPNG::Image.from_file(png_path)
      # image has double density so "display" size is half the actual one
      asciicast.image_width = image.width / 2
      asciicast.image_height = image.height / 2

      asciicast.save!
    end
  end

end
