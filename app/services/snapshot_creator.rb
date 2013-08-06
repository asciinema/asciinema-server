class SnapshotCreator

  def create(width, height, stdout, duration)
    terminal = Terminal.new(width, height)
    seconds = (duration / 2).to_i
    bytes = stdout.bytes_until(seconds)
    snapshot = terminal.feed(bytes)
    terminal.release

    snapshot
  end

end
