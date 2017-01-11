require 'open3'

class Rasterizer

  BINARY_PATH = (Rails.root + "a2png" + "a2png.sh").to_s

  def generate_image(asciicast_url, out_path, time)
    o, e, t = Open3.capture3("#{BINARY_PATH} '#{asciicast_url}' #{out_path} #{time}")

    if t.exitstatus != 0
      raise RuntimeError, "Couldn't generate image from #{asciicast_url}:\n#{o}\n#{e}"
    end
  end

end
