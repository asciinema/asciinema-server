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
        yield(*delay_and_data_for_line(file, line))
      end
    end
  end

  private

  def delay_and_data_for_line(file, line)
    delay, size = TimingParser.parse_line(line)
    data = file.read(size).force_encoding('utf-8')

    [delay, data]
  end

end
