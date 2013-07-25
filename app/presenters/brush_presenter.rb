class BrushPresenter < SimpleDelegator

  def to_css_class
    if default?
      nil
    else
      [fg_class, bg_class, bold_class, underline_class, inverse_class].compact.join(' ')
    end
  end

  private

  def fg_class
    "fg#{fg}" if fg
  end

  def bg_class
    "bg#{bg}" if bg
  end

  def bold_class
    'bold' if bold?
  end

  def underline_class
    'underline' if underline?
  end

  def inverse_class
    'inverse' if inverse?
  end

end
