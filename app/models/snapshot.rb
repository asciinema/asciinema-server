class Snapshot < Grid

  def self.build(data)
    data = data.map { |cells|
      cells.map { |cell|
        Cell.new(cell[0], Brush.new(cell[1]))
      }
    }

    new(data)
  end

  def thumbnail(w, h)
    x = 0
    y = height - h - trailing_empty_lines
    y = 0 if y < 0

    crop(x, y, w, h)
  end

  private

  def trailing_empty_lines
    n = 0

    (height - 1).downto(0) do |y|
      break unless line_empty?(y)
      n += 1
    end

    n
  end

  def line_empty?(y)
    lines[y].empty? || lines[y].all? { |cell| cell.empty? }
  end

end
