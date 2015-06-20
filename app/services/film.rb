class Film

  def initialize(stdout, terminal)
    @stdout = stdout
    @terminal = terminal
  end

  def snapshot_at(time)
    stdout_each_until(time) do |delay, data|
      terminal.feed(data)
    end

    terminal.snapshot
  end

  def frames
    frames = stdout.lazy.map do |delay, data|
      terminal.feed(data)
      [delay, Frame.new(terminal.snapshot, terminal.cursor)]
    end

    FrameDiffList.new(frames)
  end

  private

  def stdout_each_until(seconds)
    stdout.each do |delay, frame_data|
      seconds -= delay
      break if seconds <= 0
      yield(delay, frame_data)
    end
  end

  attr_reader :stdout, :terminal

end
