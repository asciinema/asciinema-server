defmodule Asciinema.Recordings.Output do
  alias Asciinema.{FileStore, StringUtils}
  alias Asciinema.Recordings.Asciicast

  def stream(%Asciicast{version: 0} = asciicast) do
    {:ok, tmp_dir_path} = Briefly.create(directory: true)
    local_timing_path = tmp_dir_path <> "/timing"
    local_data_path = tmp_dir_path <> "/data"
    store_timing_path = "asciicast/stdout_timing/#{asciicast.id}/#{asciicast.stdout_timing}"
    store_data_path = "asciicast/stdout/#{asciicast.id}/#{asciicast.stdout_data}"
    :ok = FileStore.download_file(store_timing_path, local_timing_path)
    :ok = FileStore.download_file(store_data_path, local_data_path)

    stream({local_timing_path, local_data_path})
  end

  def stream(%Asciicast{} = asciicast) do
    {:ok, local_path} = Briefly.create()
    :ok = FileStore.download_file(asciicast.path, local_path)

    stream(local_path)
  end

  def stream(path) when is_binary(path) do
    first_two_lines =
      path
      |> File.stream!([], :line)
      |> Stream.take(2)
      |> Enum.to_list()

    case first_two_lines do
      ["{" <> _ = header_line, "[" <> _] ->
        header = Jason.decode!(header_line)
        2 = header["version"]

        path
        |> File.stream!([], :line)
        |> Stream.drop(1)
        |> Stream.reject(fn line -> line == "\n" end)
        |> Stream.map(&Jason.decode!/1)
        |> Stream.map(&convert_resize_to_output/1)
        |> Stream.filter(fn [_, type, _] -> type == "o" end)
        |> Stream.map(fn [t, _, s] -> {t, s} end)
        |> to_relative_time()
        |> cap_relative_time(header["idle_time_limit"])
        |> to_absolute_time()

      ["{" <> _, _] ->
        asciicast =
          path
          |> File.read!()
          |> Jason.decode!()

        1 = asciicast["version"]

        asciicast
        |> Map.get("stdout")
        |> Enum.map(&List.to_tuple/1)
        |> to_absolute_time()
    end
  end

  def stream({timing_path, data_path}) do
    stream =
      Stream.resource(
        fn -> open_files(timing_path, data_path) end,
        &generate_elem/1,
        &close_stream_files/1
      )

    to_absolute_time(stream)
  end

  defp convert_resize_to_output([time, "r", size]) do
    [cols, rows] = String.split(size, "x")
    cols = String.to_integer(cols)
    rows = String.to_integer(rows)

    [time, "o", "\x1b[8;#{rows};#{cols}t"]
  end

  defp convert_resize_to_output(event), do: event

  defp open_files(timing_path, data_path) do
    {open_file(timing_path), open_file(data_path), ""}
  end

  defp open_file(path) do
    header = File.open!(path, [:read], fn file -> IO.binread(file, 2) end)

    case header do
      # gzip
      <<0x1F, 0x8B>> ->
        File.open!(path, [:read, :compressed])

      # bzip
      <<0x42, 0x5A>> ->
        {:ok, tmp_path} = Briefly.create()
        {_, 0} = System.cmd("sh", ["-c", "bzip2 -d -k -c #{path} >#{tmp_path}"])

        File.open!(tmp_path, [:read])

      _ ->
        File.open!(path, [:read])
    end
  end

  defp generate_elem({timing_file, data_file, invalid_str} = files) do
    case IO.read(timing_file, :line) do
      line when is_binary(line) ->
        {delay, count} = parse_line(line)

        case IO.binread(data_file, count) do
          text when is_binary(text) ->
            {valid_str, invalid_str} = StringUtils.valid_part(invalid_str, text)

            {[{delay, valid_str}], {timing_file, data_file, invalid_str}}

          otherwise ->
            {:error, otherwise}
        end

      _ ->
        {:halt, files}
    end
  end

  defp parse_line(line) do
    [delay_s, bytes_s] =
      line
      |> String.trim_trailing()
      |> String.split(" ")

    {String.to_float(delay_s), String.to_integer(bytes_s)}
  end

  defp close_stream_files({timing_file, data_file, _}) do
    File.close(timing_file)
    File.close(data_file)
  end

  defp to_absolute_time(stream) do
    Stream.scan(stream, &to_absolute_time/2)
  end

  defp to_absolute_time({curr_time, data}, {prev_time, _}) do
    {prev_time + curr_time, data}
  end

  defp to_relative_time(stream) do
    Stream.transform(stream, 0, &to_relative_time/2)
  end

  defp to_relative_time({t, s}, prev_time) do
    {[{t - prev_time, s}], t}
  end

  defp cap_relative_time({_, _} = frame, nil) do
    frame
  end

  defp cap_relative_time({t, s}, time_limit) do
    {min(t, time_limit), s}
  end

  defp cap_relative_time(stream, time_limit) do
    Stream.map(stream, &cap_relative_time(&1, time_limit))
  end
end
