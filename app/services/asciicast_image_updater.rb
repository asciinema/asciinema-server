class AsciicastImageUpdater
  PIXEL_DENSITY = 2

  attr_reader :rasterizer, :image_inspector

  def initialize(rasterizer = Rasterizer.new, image_inspector = ImageInspector.new)
    @rasterizer = rasterizer
    @image_inspector = image_inspector
  end

  def update(asciicast, page_path)
    Dir.mktmpdir do |dir|
      image_path = "#{dir}/#{asciicast.image_filename}"

      rasterizer.generate_image(page_path, image_path, 'png', '.asciinema-player', PIXEL_DENSITY)

      File.open(image_path) do |f|
        asciicast.image = f
      end

      width, height = image_inspector.get_size(image_path)

      # "display" size is 1/PIXEL_DENSITY of the actual one
      asciicast.image_width = width / PIXEL_DENSITY
      asciicast.image_height = height / PIXEL_DENSITY

      asciicast.save!
    end
  end

end
