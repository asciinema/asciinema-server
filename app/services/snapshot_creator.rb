class SnapshotCreator

  def create(width, height, stdout, duration)
    terminal = Terminal.new(width, height)
    seconds = (duration / 2).to_i

    stdout.each_until(seconds) do |delay, data|
      terminal.feed(data)
    end

    terminal.snapshot

  ensure
    terminal.release
  end

end
