class Stdout
  include Enumerable

  attr_reader :data_path, :timing_path

  def initialize(data_path, timing_path)
    @data_path = data_path
    @timing_path = timing_path
  end

  def each
    File.open(data_path, 'rb') do |file|
      File.foreach(timing_path) do |line|
        delay, size = TimingParser.parse_line(line)
        yield(delay, file.read(size).force_encoding('utf-8'))
      end
    end
  end

  def each_until(seconds)
    time = 0

    each do |delay, frame_data|
      time += delay
      break if time > seconds
      yield(delay, frame_data)
    end
  end

end
