class Grid

  attr_reader :width, :height, :lines

  def initialize(lines)
    @lines = lines
    @width = lines.first && lines.first.sum(&:size) || 0
    @height = lines.size
  end

  def crop(x, y, width, height)
    cropped_lines = lines[y...y+height].map { |line| crop_line(line, x, width) }

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

  private

  def crop_line(line, x, width)
    n = 0
    cells = []

    line.each do |cell|
      if n <= x && x < n + cell.size
        cells << cell[x-n...x-n+width]
      elsif x < n && x + width >= n + cell.size
        cells << cell
      elsif n < x + width && x + width < n + cell.size
        cells << cell[0...x+width-n]
      end

      n += cell.size
    end

    cells
  end

end
