class Snapshot

  delegate :width, :height, :cell, :to => :grid

  def self.build(data)
    data = data.map { |cells|
      cells.map { |cell|
        Cell.new(cell[0], Brush.new(cell[1]))
      }
    }

    grid = Grid.new(data)

    new(grid)
  end

  def initialize(grid)
    @grid = grid
  end

  def thumbnail(w, h)
    x = 0
    y = height - h - grid.trailing_empty_lines
    y = 0 if y < 0
    cropped_grid = grid.crop(x, y, w, h)

    self.class.new(cropped_grid)
  end

  private

  attr_reader :grid

end
