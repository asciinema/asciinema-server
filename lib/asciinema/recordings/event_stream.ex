defmodule Asciinema.Recordings.EventStream do
  def to_absolute_time(stream) do
    Stream.scan(stream, &to_absolute_time/2)
  end

  defp to_absolute_time({curr_time, code, data}, {prev_time, _, _}) do
    {prev_time + curr_time, code, data}
  end

  def to_relative_time(stream) do
    Stream.transform(stream, 0, &to_relative_time/2)
  end

  defp to_relative_time({curr_time, code, data}, prev_time) do
    {[{curr_time - prev_time, code, data}], curr_time}
  end

  def cap_relative_time({_, _, _} = frame, nil) do
    frame
  end

  def cap_relative_time({time, code, data}, time_limit) do
    {min(time, time_limit), code, data}
  end

  def cap_relative_time(stream, time_limit) do
    Stream.map(stream, &cap_relative_time(&1, time_limit))
  end
end
