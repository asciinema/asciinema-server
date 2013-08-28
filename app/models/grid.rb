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
    self.class.new(lines[y...y+height].map { |line| line[x...x+width] })
  end

  def diff(other)
    (0...height).each_with_object({}) do |y, diff|
      if other.lines[y] != lines[y]
        diff[y] = other.lines[y]
      end
    end
  end

  def trailing_empty_lines
    n = 0

    (height - 1).downto(0) do |y|
      break unless line_empty?(y)
      n += 1
    end

    n
  end

  protected

  attr_reader :lines

  private

  def line_empty?(y)
    lines[y].empty? || lines[y].all? { |item| item.empty? }
  end

end
