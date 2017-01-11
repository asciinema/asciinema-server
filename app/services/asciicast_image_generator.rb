class AsciicastImageGenerator
  PIXEL_DENSITY = 2

  attr_reader :template_renderer, :rasterizer, :image_inspector

  def initialize(template_renderer, rasterizer = Rasterizer.new, image_inspector = ImageInspector.new)
    @template_renderer = template_renderer
    @rasterizer = rasterizer
    @image_inspector = image_inspector
  end

  def generate(asciicast)
    Dir.mktmpdir do |dir|
      asciicast_url = asciicast.file.absolute_url
      image_path = "#{dir}/#{asciicast.image_filename}"
      time = asciicast.snapshot_at || asciicast.duration / 2
      theme = AsciicastDecorator.new(asciicast).theme_name

      rasterizer.generate_image(asciicast_url, image_path, time, PIXEL_DENSITY, theme)
      image_width, image_height = get_size(image_path)

      update_asciicast(asciicast, image_path, image_width, image_height)
    end
  end

  private

  def get_size(image_path)
    width, height = image_inspector.get_size(image_path)

    # "display" size is 1/PIXEL_DENSITY of the actual one
    [width / PIXEL_DENSITY, height / PIXEL_DENSITY]
  end

  def update_asciicast(asciicast, image_path, image_width, image_height)
    File.open(image_path) do |f|
      asciicast.image = f
    end

    asciicast.image_width = image_width
    asciicast.image_height = image_height

    asciicast.save!
  end

end
