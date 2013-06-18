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
    file = asciicast.stdout_timing
    file.cache_stored_file! unless file.cached?
    lines = unbzip(file.file.path).lines

    timing = lines.map do |line|
      delay, n = line.split
      delay = delay.to_f
      n = n.to_i
      [delay, n]
    end
  end

  def get_stdout
    file = asciicast.stdout
    file.cache_stored_file! unless file.cached?
    unbzip(file.file.path)
  end

  private

  def unbzip(path)
    f = IO.popen "bzip2 -d -c #{path}", "r"
    data = f.read
    f.close

    data
  end

  def log(text, level = :info)
    Rails.logger.send(level, "SnapshotWorker: #{text}")
  end
end
