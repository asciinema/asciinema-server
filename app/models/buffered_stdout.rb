class BufferedStdout < Stdout

  MIN_FRAME_LENGTH = 1.0 / 60

  def each
    buffered_delay, buffered_data = 0.0, []

    super do |delay, data|
      if buffered_delay + delay < MIN_FRAME_LENGTH
        buffered_delay += delay
        buffered_data << data
      else
        yield(buffered_delay, buffered_data.join)
        buffered_delay = delay
        buffered_data = [data]
      end
    end

    yield(buffered_delay, buffered_data.join) unless buffered_data.empty?
  end

end
