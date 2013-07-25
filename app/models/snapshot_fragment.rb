class SnapshotFragment

  attr_reader :text, :brush

  def initialize(text, brush)
    @text = text
    @brush = brush
  end

  def ==(other)
    other.text == text && other.brush == brush
  end

  def crop(size)
    if size >= text.size
      self
    else
      self.class.new(text[0...size], brush)
    end
  end

end
