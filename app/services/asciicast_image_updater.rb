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

      asciicast.save!
    end
  end

end
