class Cell

  attr_reader :text, :brush

  def initialize(text, brush)
    @text = text
    @brush = brush
  end

  def empty?
    text.blank? && brush.default?
  end

  def ==(other)
    text == other.text && brush == other.brush
  end

  def css_class
    BrushPresenter.new(brush).to_css_class
  end

end
