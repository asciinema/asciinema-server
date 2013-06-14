class SnapshotWorker
  attr_reader :asciicast

  def perform(asciicast_id)
    @asciicast = Asciicast.find(asciicast_id)

    delay = (asciicast.duration / 2).to_i
    delay = 30 if delay > 30

    asciicast.snapshot = create_snapshot(delay)
    asciicast.save!

  rescue ActiveRecord::RecordNotFound
    # oh well...
  end

  def create_snapshot(delay)
    data = get_data_to_feed(delay)
    screen = TSM::Screen.new(asciicast.terminal_columns,
                             asciicast.terminal_lines)
    vte = TSM::Vte.new(screen)
    vte.input(data)
    screen.snapshot.to_s
  end

  def get_data_to_feed(delay)
    timing = get_timing
    stdout = get_stdout

    i = 0
    time = 0
    bytes_to_feed = 0
    while time < delay
      time += timing[i][0]
      bytes_to_feed += timing[i][1]
      i += 1
    end

    stdout.bytes.take(bytes_to_feed)
  end

  def get_timing
    lines = unbzip(asciicast.stdout_timing.file.read).lines

    timing = lines.map do |line|
      delay, n = line.split
      delay = delay.to_f
      n = n.to_i
      [delay, n]
    end
  end

  def get_stdout
    unbzip(asciicast.stdout.file.read)
  end

  private

  def unbzip(compressed_data)
    f = IO.popen "bzip2 -d", "r+"
    f.write(compressed_data)
    f.close_write
    uncompressed_data = f.read
    f.close

    uncompressed_data
  end

  def log(text, level = :info)
    Rails.logger.send(level, "SnapshotWorker: #{text}")
  end
end
