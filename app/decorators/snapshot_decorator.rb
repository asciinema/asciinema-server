class SnapshotDecorator < ApplicationDecorator

  delegate_all

  def lines
    model.lines.map { |line| decorate_cells(line) }
  end

  private

  def decorate_cells(cells)
    cells.map { |cell| CellDecorator.new(cell) }
  end

end
