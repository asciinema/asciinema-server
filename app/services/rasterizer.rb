require 'open3'

class Rasterizer

  BINARY_PATH = (Rails.root + "bin" + "rasterize").to_s

  def generate_image(page_path, image_path, format, selector, scale)
    o, e, t = Open3.capture3("#{BINARY_PATH} #{page_path} #{image_path} #{format} #{selector} #{scale}")

    if t.exitstatus != 0
      raise RuntimeError, "Couldn't generate image from #{page_path}:\n#{o}\n#{e}"
    end
  end

end
