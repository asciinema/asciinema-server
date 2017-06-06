class BrushDecorator < ApplicationDecorator

  def css_class
    if model.default?
      nil
    else
      classes = [fg_class, bg_class, bold_class, underline_class]
      classes.compact.join(' ')
    end
  end

  def css_style
    attrs = {}

    if Brush.rgb_color?(model.fg)
      r, g, b = model.fg
      attrs['color'] = "rgb(#{r},#{g},#{b})"
    end

    if Brush.rgb_color?(model.bg)
      r, g, b = model.bg
      attrs['background-color'] = "rgb(#{r},#{g},#{b})"
    end

    if !attrs.empty?
      attrs.reduce("") { |acc, kv| acc + "#{kv[0]}:#{kv[1]};" }
    end
  end

  private

  def fg_class
    "fg-#{model.fg}" if model.fg && !Brush.rgb_color?(model.fg)
  end

  def bg_class
    "bg-#{model.bg}" if model.bg && !Brush.rgb_color?(model.bg)
  end

  def bold_class
    'bright' if model.bold?
  end

  def underline_class
    'underline' if model.underline?
  end

end
