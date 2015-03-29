require 'open3'

class ImageInspector

  def get_size(image_path)
    o, e, t = Open3.capture3(%(identify -format "%[fx:w]x%[fx:h]" #{image_path}))

    if t.exitstatus != 0
      raise RuntimeError, "Couldn't inspect image #{image_path}:\n#{o}\n#{e}"
    end

    o.split('x').map(&:to_i)
  end

end
