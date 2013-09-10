class SnapshotDecorator < ApplicationDecorator

  delegate_all

  def lines
    (0...height).map { |line_no| line(line_no) }
  end

  private

  def line(line_no)
    line = (0...width).map { |column_no| model.cell(column_no, line_no) }

    decorate_cells(optimize_line(line))
  end

  def optimize_line(line)
    LineOptimizer.new.optimize(line)
  end

  def decorate_cells(cells)
    cells.map { |cell| CellDecorator.new(cell) }
  end

end
