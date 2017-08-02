defmodule Asciinema.Asciicasts do
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, FileStore, StringUtils, Vt}
  alias Asciinema.Asciicasts.{Asciicast, SnapshotUpdater, FramesGenerator}

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
          from a in Asciicast, where: a.id == -1 # TODO fixme
      end
    end

    Repo.one!(q)
  end

  def create_asciicast(user, params, overrides \\ %{})

  def create_asciicast(user, %Plug.Upload{path: path, filename: filename} = upload, overrides) do
    asciicast = %Asciicast{user_id: user.id,
                           file: filename,
                           private: user.asciicasts_private_by_default}

    files = [{:file, upload, true}]

    with {:ok, json} <- File.read(path),
         {:ok, attrs} <- Poison.decode(json),
         {:ok, attrs} <- extract_attrs(attrs),
         attrs = Map.merge(attrs, overrides),
         changeset = Asciicast.create_changeset(asciicast, attrs),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, files) do
      :ok = SnapshotUpdater.update_snapshot(asciicast)
      {:ok, asciicast}
    else
      {:error, :invalid} ->
        {:error, :parse_error}
      otherwise ->
        otherwise
    end
  end

  def create_asciicast(user, %{"meta" => meta,
                               "stdout" => %Plug.Upload{} = data,
                               "stdout_timing" => %Plug.Upload{} = timing}, overrides) do
    asciicast = %Asciicast{user_id: user.id,
                           stdout_data: data.filename,
                           stdout_timing: timing.filename,
                           private: user.asciicasts_private_by_default}

    {:ok, attrs} = extract_attrs(meta)
    attrs = Map.merge(attrs, overrides)
    attrs = if attrs[:uname], do: Map.drop(attrs, [:user_agent]), else: attrs
    changeset = Asciicast.create_changeset(asciicast, attrs)
    files = [{:stdout_data, data, false}, {:stdout_timing, timing, false}]

    case do_create_asciicast(changeset, files) do
      {:ok, %Asciicast{} = asciicast} ->
        :ok = FramesGenerator.generate_frames(asciicast)
        :ok = SnapshotUpdater.update_snapshot(asciicast)
        {:ok, asciicast}
      otherwise ->
        otherwise
    end
  end

  defp extract_attrs(%{"version" => 0} = attrs) do
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
  defp extract_attrs(%{"version" => 1} = attrs) do
    attrs = %{version: 1,
              terminal_columns: attrs["width"],
              terminal_lines: attrs["height"],
              terminal_type: get_in(attrs, ["env", "TERM"]),
              command: attrs["command"],
              duration: attrs["duration"],
              title: attrs["title"],
              shell: get_in(attrs, ["env", "SHELL"])}

    {:ok, attrs}
  end
  defp extract_attrs(_attrs) do
    {:error, :unknown_format}
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
  def stdout_stream(%Asciicast{version: 1} = asciicast) do
    {:ok, local_path} = Briefly.create()
    store_path = Asciicast.file_store_path(asciicast, :file)
    :ok = FileStore.download_file(store_path, local_path)
    stdout_stream(local_path)
  end
  def stdout_stream(asciicast_file_path) when is_binary(asciicast_file_path) do
    asciicast =
      asciicast_file_path
      |> File.read!
      |> Poison.decode!

    1 = asciicast["version"]

    asciicast
    |> Map.get("stdout")
    |> Enum.map(&List.to_tuple/1)
  end
  def stdout_stream({stdout_timing_path, stdout_data_path}) do
    Stream.resource(
      fn -> open_stream_files(stdout_timing_path, stdout_data_path) end,
      &generate_stream_elem/1,
      &close_stream_files/1
    )
  end

  defp open_stream_files(stdout_timing_path, stdout_data_path) do
    {open_stream_file(stdout_timing_path),
     open_stream_file(stdout_data_path),
     ""}
  end

  defp open_stream_file(path) do
    header = File.open!(path, [:read], fn file -> IO.binread(file, 2) end)

    case header do
      <<0x1f,0x8b>> -> # gzip
        File.open!(path, [:read, :compressed])
      <<0x42,0x5a>> -> # bzip
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
    frames =
      stdout_stream
      |> Stream.scan(&to_absolute_time/2)
      |> Stream.take_while(&frame_before_or_at?(&1, secs))

    {:ok, %{"lines" => lines}} = Vt.with_vt(width, height, fn vt ->
      Enum.each(frames, fn {_, text} -> Vt.feed(vt, text) end)
      Vt.dump_screen(vt, 30_000)
    end)

    lines
  end

  defp to_absolute_time({curr_time, data}, {prev_time, _}) do
    {prev_time + curr_time, data}
  end

  defp frame_before_or_at?({time, _}, secs) do
    time <= secs
  end
end
