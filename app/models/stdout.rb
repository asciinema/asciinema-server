class Stdout
  include Enumerable

  attr_reader :data, :timing

  def initialize(data, timing)
    @data = data
    @timing = timing
  end

  def each
    offset = 0

    timing.each do |line|
      delay, size = line
      yield(delay, bytes[offset...offset+size])
      offset += size
    end
  end

  def bytes_until(seconds)
    bytes = []
    time = 0

    each do |delay, frame_bytes|
      time += delay
      break if time > seconds
      bytes.concat(frame_bytes)
    end

    bytes
  end

  private

  def bytes
    @bytes ||= data.bytes
  end

end
