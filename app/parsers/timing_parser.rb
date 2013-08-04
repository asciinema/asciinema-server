class TimingParser

  def self.parse(data)
    data.lines.map do |line|
      delay, size = line.split
      [delay.to_f, size.to_i]
    end
  end

end
