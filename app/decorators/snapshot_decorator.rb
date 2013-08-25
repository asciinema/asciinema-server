class SnapshotDecorator < ApplicationDecorator

  delegate_all

  def lines
    (0...height).map { |line_no| line(line_no) }
  end

  private

  def line(line_no)
    (0...width).map { |column_no| model.cell(column_no, line_no) }
  end

end
