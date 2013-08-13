class TimingParser

  def self.parse(data)
    data.lines.map { |line| parse_line(line) }
  end

  def self.parse_line(line)
    delay, size = line.split
    [delay.to_f, size.to_i]
  end

end
