class LineOptimizer

  def optimize(line)
    return [] if line.empty?

    text = [line[0].text]
    brush = line[0].brush

    cells = []

    line[1..-1].each do |cell|
      if cell.brush == brush
        text << cell.text
      else
        cells << Cell.new(text.join, brush)
        text, brush = [cell.text], cell.brush
      end
    end

    cells << Cell.new(text.join, brush)

    cells
  end

end
