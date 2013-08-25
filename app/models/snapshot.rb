class Snapshot

  attr_reader :width, :height

  def initialize(data, raw = true)
    @lines = raw ? cellify(data) : data
    @width = lines.first && lines.first.size || 0
    @height = lines.size
  end

  def cell(column, line)
    lines[line][column]
  end

  def thumbnail(width, height)
    new_lines = strip_trailing_blank_lines(lines)
    new_lines = crop_at_bottom_left(new_lines, width, height)
    new_lines = expand(new_lines, width, height)

    self.class.new(new_lines, false)
  end

  protected

  def strip_trailing_blank_lines(lines)
    i = lines.size - 1

    while i >= 0 && empty_line?(lines[i])
      i -= 1
    end

    i > -1 ? lines[0..i] : []
  end

  def crop_at_bottom_left(lines, width, height)
    min_height = [height, lines.size].min

    lines.drop(lines.size - min_height).map { |line| line.take(width) }
  end

  def expand(lines, width, height)
    while lines.size < height
      lines << [Cell.new(' ', Brush.new)] * width
    end

    lines
  end

  private

  attr_reader :lines

  def cellify(lines)
    lines.map { |cells|
      cells.map { |cell|
        Cell.new(cell[0], Brush.new(cell[1]))
      }
    }
  end

  def empty_line?(cells)
    cells.all?(&:empty?)
  end

end
