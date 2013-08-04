class SnapshotFragment # TODO: rename to Cell or SnapshotCell

  attr_reader :text, :brush

  delegate :size, :to => :text

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
