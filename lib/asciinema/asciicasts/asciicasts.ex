defmodule Asciinema.Asciicasts do
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, FileStore, StringUtils, Vt}
  alias Asciinema.Asciicasts.{Asciicast, SnapshotUpdater}

  def get_asciicast!(id) when is_integer(id) do
    Repo.get!(Asciicast, id)
  end
  def get_asciicast!(thing) when is_binary(thing) do
    q = if String.length(thing) == 25 do
      from a in Asciicast, where: a.secret_token == ^thing
    else
      case Integer.parse(thing) do
        {id, ""} ->
          from a in Asciicast, where: a.private == false and a.id == ^id
        _ ->
          from a in Asciicast, where: false
      end
    end

    Repo.one!(q)
  end

  def create_asciicast(user, params, overrides \\ %{})

  def create_asciicast(user, %Plug.Upload{filename: filename} = upload, overrides) do
    asciicast = %Asciicast{user_id: user.id,
                           file: filename,
                           private: user.asciicasts_private_by_default}

    files = [{:file, upload, true}]

    with {:ok, attrs} <- extract_metadata(upload),
         attrs = Map.merge(attrs, overrides),
         changeset = Asciicast.create_changeset(asciicast, attrs),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, files) do
      :ok = SnapshotUpdater.update_snapshot(asciicast)
      {:ok, asciicast}
    end
  end

  def create_asciicast(user, %{"meta" => meta,
                               "stdout" => %Plug.Upload{} = data,
                               "stdout_timing" => %Plug.Upload{} = timing}, overrides) do
    {:ok, attrs} = extract_metadata(meta)

    header = %{version: 2,
               width: attrs[:terminal_columns],
               height: attrs[:terminal_lines],
               title: attrs[:title],
               command: attrs[:command],
               env: %{"SHELL" => attrs[:shell],
                      "TERM" => attrs[:terminal_type]}}

    header =
      header
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.into(%{})

    overrides = if uname = attrs[:uname] do
      overrides
      |> Map.put(:uname, uname)
      |> Map.drop([:user_agent])
    else
      Map.put(overrides, :uname, uname)
    end

    {:ok, tmp_path} = Briefly.create()

    File.open!(tmp_path, [:write, :utf8], fn f ->
      :ok = IO.write(f, "#{Poison.encode!(header, pretty: false)}\n")

      {timing.path, data.path}
      |> stdout_stream
      |> Enum.each(fn {t, s} ->
        event = [t, "o", s]
        :ok = IO.write(f, "#{Poison.encode!(event, pretty: false)}\n")
      end)
    end)

    upload = %Plug.Upload{path: tmp_path,
                          filename: "0.cast",
                          content_type: "application/octet-stream"}

    create_asciicast(user, upload, overrides)
  end

  defp extract_metadata(%{"version" => 0} = attrs) do
    attrs = %{version: 0,
              terminal_columns: get_in(attrs, ["term", "columns"]),
              terminal_lines: get_in(attrs, ["term", "lines"]),
              terminal_type: get_in(attrs, ["term", "type"]),
              command: attrs["command"],
              duration: attrs["duration"],
              title: attrs["title"],
              shell: attrs["shell"],
              uname: attrs["uname"]}

    {:ok, attrs}
  end

  defp extract_metadata(%Plug.Upload{path: path}) do
    case extract_v2_metadata(path) do
      {:error, :unknown_format} -> extract_v1_metadata(path)
      result -> result
    end
  end

  defp extract_v1_metadata(path) do
    with {:ok, json} <- File.read(path),
         {:ok, %{"version" => 1} = attrs} <- decode_json(json) do
      metadata = %{version: 1,
                   terminal_columns: attrs["width"],
                   terminal_lines: attrs["height"],
                   terminal_type: get_in(attrs, ["env", "TERM"]),
                   command: attrs["command"],
                   duration: attrs["duration"],
                   title: attrs["title"],
                   shell: get_in(attrs, ["env", "SHELL"])}
      {:ok, metadata}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:unsupported_format, version}}
      {:error, :invalid} ->
        {:error, :unknown_format}
    end
  end

  defp extract_v2_metadata(path) do
    with {:ok, line} when is_binary(line) <- File.open(path, fn f -> IO.read(f, :line) end),
         {:ok, %{"version" => 2} = header} <- decode_json(line) do
      metadata = %{version: 2,
                   terminal_columns: header["width"],
                   terminal_lines: header["height"],
                   terminal_type: get_in(header, ["env", "TERM"]),
                   command: header["command"],
                   duration: get_v2_duration(path),
                   recorded_at: header["timestamp"] && Timex.from_unix(header["timestamp"]),
                   title: header["title"],
                   theme_fg: get_in(header, ["theme", "fg"]),
                   theme_bg: get_in(header, ["theme", "bg"]),
                   theme_palette: get_in(header, ["theme", "palette"]),
                   idle_time_limit: header["idle_time_limit"],
                   shell: get_in(header, ["env", "SHELL"])}
      {:ok, metadata}
    else
      {:ok, :eof} ->
        {:error, :unknown_format}
      {:ok, %{"version" => version}} ->
        {:error, {:unsupported_format, version}}
      {:error, :invalid} ->
        {:error, :unknown_format}
    end
  end

  defp get_v2_duration(path) do
    path
    |> stdout_stream
    |> Enum.reduce(fn {t, _}, _prev_t -> t end)
  end

  defp decode_json(json) do
    case Poison.decode(json) do
      {:ok, thing} -> {:ok, thing}
      {:error, :invalid, _} -> {:error, :invalid}
      {:error, {:invalid, _, _}} -> {:error, :invalid}
    end
  end

  defp do_create_asciicast(changeset, files) do
    {_, result} = Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, %Asciicast{} = asciicast} ->
          Enum.each(files, &save_file(asciicast, &1))
          {:ok, asciicast}
        otherwise ->
          otherwise
      end
    end)

    result
  end

  defp save_file(asciicast, {type, %{path: tmp_path, content_type: content_type}, compress}) do
    file_store_path = Asciicast.file_store_path(asciicast, type)
    :ok = FileStore.put_file(file_store_path, tmp_path, content_type, compress)
  end

  def stdout_stream(%Asciicast{version: 0} = asciicast) do
    {:ok, tmp_dir_path} = Briefly.create(directory: true)
    local_timing_path = tmp_dir_path <> "/timing"
    local_data_path = tmp_dir_path <> "/data"
    store_timing_path = Asciicast.file_store_path(asciicast, :stdout_timing)
    store_data_path = Asciicast.file_store_path(asciicast, :stdout_data)
    :ok = FileStore.download_file(store_timing_path, local_timing_path)
    :ok = FileStore.download_file(store_data_path, local_data_path)
    stdout_stream({local_timing_path, local_data_path})
  end
  def stdout_stream(%Asciicast{} = asciicast) do
    {:ok, local_path} = Briefly.create()
    store_path = Asciicast.file_store_path(asciicast, :file)
    :ok = FileStore.download_file(store_path, local_path)
    stdout_stream(local_path)
  end
  def stdout_stream(asciicast_file_path) when is_binary(asciicast_file_path) do
    first_two_lines =
      asciicast_file_path
      |> File.stream!([], :line)
      |> Stream.take(2)
      |> Enum.to_list

    case first_two_lines do
      ["{" <> _ = header_line, "[" <> _] ->
        header = Poison.decode!(header_line)
        2 = header["version"]

        asciicast_file_path
        |> File.stream!([], :line)
        |> Stream.drop(1)
        |> Stream.reject(fn line -> line == "\n" end)
        |> Stream.map(&Poison.decode!/1)
        |> Stream.filter(fn [_, type, _] -> type == "o" end)
        |> Stream.map(fn [t, _, s] -> {t, s} end)
        |> to_relative_time
        |> cap_relative_time(header["idle_time_limit"])
        |> to_absolute_time

      ["{" <> _, _] ->
        asciicast =
          asciicast_file_path
          |> File.read!
          |> Poison.decode!

        1 = asciicast["version"]

        asciicast
        |> Map.get("stdout")
        |> Enum.map(&List.to_tuple/1)
        |> to_absolute_time
    end
  end
  def stdout_stream({stdout_timing_path, stdout_data_path}) do
    stream = Stream.resource(
      fn -> open_stream_files(stdout_timing_path, stdout_data_path) end,
      &generate_stream_elem/1,
      &close_stream_files/1
    )

    to_absolute_time(stream)
  end

  defp open_stream_files(stdout_timing_path, stdout_data_path) do
    {open_stream_file(stdout_timing_path),
     open_stream_file(stdout_data_path),
     ""}
  end

  defp open_stream_file(path) do
    header = File.open!(path, [:read], fn file -> IO.binread(file, 2) end)

    case header do
      <<0x1f, 0x8b>> -> # gzip
        File.open!(path, [:read, :compressed])
      <<0x42, 0x5a>> -> # bzip
        {:ok, tmp_path} = Briefly.create()
        {_, 0} = System.cmd("sh", ["-c", "bzip2 -d -k -c #{path} >#{tmp_path}"])
        File.open!(tmp_path, [:read])
      _ ->
        File.open!(path, [:read])
    end
  end

  defp generate_stream_elem({timing_file, data_file, invalid_str} = files) do
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

  defp close_stream_files({timing_file, data_file, _}) do
    File.close(timing_file)
    File.close(data_file)
  end

  defp parse_line(line) do
    [delay_s, bytes_s] = line |> String.trim_trailing |> String.split(" ")
    {String.to_float(delay_s), String.to_integer(bytes_s)}
  end

  def update_snapshot(%Asciicast{terminal_columns: w, terminal_lines: h} = asciicast) do
    secs = Asciicast.snapshot_at(asciicast)
    snapshot = asciicast |> stdout_stream |> generate_snapshot(w, h, secs)
    asciicast |> Asciicast.snapshot_changeset(snapshot) |> Repo.update
  end

  def generate_snapshot(stdout_stream, width, height, secs) do
    frames = Stream.take_while(stdout_stream, &frame_before_or_at?(&1, secs))

    {:ok, %{"lines" => lines}} = Vt.with_vt(width, height, fn vt ->
      Enum.each(frames, fn {_, text} -> Vt.feed(vt, text) end)
      Vt.dump_screen(vt, 30_000)
    end)

    lines
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

  defp frame_before_or_at?({time, _}, secs) do
    time <= secs
  end
end
