class Snapshot

  attr_reader :lines

  def initialize(lines = [])
    @lines = lines
  end

  def ==(other)
    other.lines == lines
  end

  def crop(width, height)
    new_lines = lines.drop(lines.size - height).map { |line| line.crop(width) }
    self.class.new(new_lines)
  end

end
