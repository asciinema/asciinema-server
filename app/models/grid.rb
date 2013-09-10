class Grid

  attr_reader :width, :height

  def initialize(lines)
    @lines = lines
    @width = lines.first && lines.first.size || 0
    @height = lines.size
  end

  def ==(other)
    lines == other.lines
  end

  def cell(x, y)
    lines[y][x]
  end

  def crop(x, y, width, height)
    cropped_lines = lines[y...y+height].map { |line| line[x...x+width] }
    self.class.new(cropped_lines)
  end

  def diff(other)
    (0...height).each_with_object({}) do |y, diff|
      if other.nil? || other.lines[y] != lines[y]
        diff[y] = lines[y]
      end
    end
  end

  def as_json(*)
    lines.as_json
  end

  protected

  attr_reader :lines

end
