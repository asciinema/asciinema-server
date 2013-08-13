class Stdout
  include Enumerable

  attr_reader :data_file, :timing_file

  def initialize(data_file, timing_file)
    @data_file = data_file
    @timing_file = timing_file
  end

  def each
    File.open(data_file.decompressed_path, 'rb') do |file|
      File.foreach(timing_file.decompressed_path) do |line|
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
