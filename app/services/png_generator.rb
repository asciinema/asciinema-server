require 'open3'

class PngGenerator

  BINARY_PATH = (Rails.root + "bin" + "asciicast2png").to_s

  def generate(page_path, png_path)
    o, e, t = Open3.capture3("#{BINARY_PATH} #{page_path} #{png_path}")

    if t.exitstatus != 0
      raise RuntimeError, "Couldn't generate PNG for #{page_path}:\n#{o}\n#{e}"
    end
  end

end
