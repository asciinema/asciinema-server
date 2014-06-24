class BrushDecorator < ApplicationDecorator

  def css_class
    if model.default?
      nil
    else
      classes = [fg_class, bg_class, bold_class, underline_class]
      classes.compact.join(' ')
    end
  end

  private

  def fg_class
    "fg-#{model.fg}" if model.fg
  end

  def bg_class
    "bg-#{model.bg}" if model.bg
  end

  def bold_class
    'bright' if model.bold?
  end

  def underline_class
    'underline' if model.underline?
  end

end
