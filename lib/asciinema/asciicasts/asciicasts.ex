defmodule Asciinema.Asciicasts do
  require Logger
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, FileStore, StringUtils, Vt}
  alias Asciinema.Asciicasts.{Asciicast, SnapshotUpdater}
  alias Ecto.Changeset

  def get_asciicast!(id) when is_integer(id) do
    Asciicast
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  def get_asciicast!(thing) when is_binary(thing) do
    q =
      if String.length(thing) == 25 do
        from(a in Asciicast, where: a.secret_token == ^thing)
      else
        case Integer.parse(thing) do
          {id, ""} ->
            from(a in Asciicast, where: a.private == false and a.id == ^id)

          _ ->
            from(a in Asciicast, where: false)
        end
      end

    q
    |> Repo.one!()
    |> Repo.preload(:user)
  end

  def get_homepage_asciicast do
    asciicast =
      if id = Application.get_env(:asciinema, :home_asciicast_id) do
        Repo.get(Asciicast, id)
      else
        :public
        |> category_asciicasts()
        |> first()
        |> Repo.one()
      end

    Repo.preload(asciicast, :user)
  end

  def list_homepage_asciicasts() do
    year_ago = Timex.now() |> Timex.shift(years: -1)

    :featured
    |> category_asciicasts()
    |> where([a], a.created_at > ^year_ago)
    |> order_by(fragment("RANDOM()"))
    |> limit(6)
    |> preload(:user)
    |> Repo.all()
  end

  def other_public_asciicasts(asciicast, limit \\ 3) do
    q =
      from(
        a in Asciicast,
        where: a.id != ^asciicast.id and a.user_id == ^asciicast.user_id and a.private == false,
        order_by: fragment("RANDOM()"),
        limit: ^limit,
        preload: :user
      )

    Repo.all(q)
  end

  def category_asciicasts(category) do
    from(Asciicast)
    |> filter(category)
  end

  defp filter(q, :featured) do
    where(q, [a], a.featured == true and a.private == false and is_nil(a.archived_at))
  end

  defp filter(q, :public) do
    where(q, [a], a.private == false and is_nil(a.archived_at))
  end

  defp filter(q, :all) do
    where(q, [a], is_nil(a.archived_at))
  end

  defp sort(q, :date), do: order_by(q, desc: :id)
  defp sort(q, :popularity), do: order_by(q, desc: :views_count)

  def paginate_asciicasts(q, order, page, page_size) do
    from(q)
    |> sort(order)
    |> preload(:user)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def count_asciicasts(q \\ Asciicast) do
    Repo.count(q)
  end

  def ensure_welcome_asciicast(user) do
    if Repo.count(Ecto.assoc(user, :asciicasts)) == 0 do
      upload = %Plug.Upload{
        path: Path.join(:code.priv_dir(:asciinema), "welcome.json"),
        filename: "asciicast.json",
        content_type: "application/json"
      }

      {:ok, _} = create_asciicast(user, upload, %{private: false, snapshot_at: 76.2})
    end

    :ok
  end

  def create_asciicast(user, params, overrides \\ %{})

  def create_asciicast(user, %Plug.Upload{filename: filename} = upload, overrides) do
    asciicast = %Asciicast{
      user_id: user.id,
      file: filename,
      private: user.asciicasts_private_by_default
    }

    files = [{:file, upload, true}]

    with {:ok, attrs} <- extract_metadata(upload),
         attrs = Map.merge(attrs, overrides),
         changeset = Asciicast.create_changeset(asciicast, attrs),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, files) do
      :ok = SnapshotUpdater.update_snapshot(asciicast)
      {:ok, asciicast}
    end
  end

  def create_asciicast(
        user,
        %{
          "meta" => meta,
          "stdout" => %Plug.Upload{} = data,
          "stdout_timing" => %Plug.Upload{} = timing
        },
        overrides
      ) do
    {:ok, attrs} = extract_metadata(meta)

    header = %{
      version: 2,
      width: attrs[:terminal_columns],
      height: attrs[:terminal_lines],
      title: attrs[:title],
      command: attrs[:command],
      env: %{"SHELL" => attrs[:shell], "TERM" => attrs[:terminal_type]}
    }

    header =
      header
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.into(%{})

    overrides =
      if uname = attrs[:uname] do
        overrides
        |> Map.put(:uname, uname)
        |> Map.drop([:user_agent])
      else
        Map.put(overrides, :uname, uname)
      end

    tmp_path =
      {timing.path, data.path}
      |> stdout_stream()
      |> write_v2_file(header)

    upload = %Plug.Upload{
      path: tmp_path,
      filename: "0.cast",
      content_type: "application/octet-stream"
    }

    create_asciicast(user, upload, overrides)
  end

  defp extract_metadata(%{"version" => 0} = attrs) do
    attrs = %{
      version: 0,
      terminal_columns: get_in(attrs, ["term", "columns"]),
      terminal_lines: get_in(attrs, ["term", "lines"]),
      terminal_type: get_in(attrs, ["term", "type"]),
      command: attrs["command"],
      duration: attrs["duration"],
      title: attrs["title"],
      shell: attrs["shell"],
      uname: attrs["uname"]
    }

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
      metadata = %{
        version: 1,
        terminal_columns: attrs["width"],
        terminal_lines: attrs["height"],
        terminal_type: get_in(attrs, ["env", "TERM"]),
        command: attrs["command"],
        duration: attrs["duration"],
        title: attrs["title"],
        shell: get_in(attrs, ["env", "SHELL"])
      }

      {:ok, metadata}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:unsupported_format, version}}

      otherwise ->
        Logger.warn("error extracting v1 metadata: #{inspect(otherwise)}")
        {:error, :unknown_format}
    end
  end

  defp extract_v2_metadata(path) do
    with {:ok, line} when is_binary(line) <- File.open(path, fn f -> IO.read(f, :line) end),
         {:ok, %{"version" => 2} = header} <- decode_json(line) do
      metadata = %{
        version: 2,
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
        shell: get_in(header, ["env", "SHELL"])
      }

      {:ok, metadata}
    else
      {:ok, %{"version" => version}} ->
        {:error, {:unsupported_format, version}}

      otherwise ->
        Logger.warn("error extracting v2 metadata: #{inspect(otherwise)}")
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
    {_, result} =
      Repo.transaction(fn ->
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

  defp delete_file(asciicast, type) do
    :ok =
      asciicast
      |> Asciicast.file_store_path(type)
      |> FileStore.delete_file()
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
      |> Enum.to_list()

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
          |> File.read!()
          |> Poison.decode!()

        1 = asciicast["version"]

        asciicast
        |> Map.get("stdout")
        |> Enum.map(&List.to_tuple/1)
        |> to_absolute_time
    end
  end

  def stdout_stream({stdout_timing_path, stdout_data_path}) do
    stream =
      Stream.resource(
        fn -> open_stream_files(stdout_timing_path, stdout_data_path) end,
        &generate_stream_elem/1,
        &close_stream_files/1
      )

    to_absolute_time(stream)
  end

  defp open_stream_files(stdout_timing_path, stdout_data_path) do
    {open_stream_file(stdout_timing_path), open_stream_file(stdout_data_path), ""}
  end

  defp open_stream_file(path) do
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
    [delay_s, bytes_s] = line |> String.trim_trailing() |> String.split(" ")
    {String.to_float(delay_s), String.to_integer(bytes_s)}
  end

  def change_asciicast(asciicast, attrs \\ %{}) do
    Asciicast.update_changeset(asciicast, attrs)
  end

  def update_asciicast(asciicast, attrs \\ %{}) do
    changeset = Asciicast.update_changeset(asciicast, attrs)

    with {:ok, asciicast} <- Repo.update(changeset) do
      case Changeset.get_change(changeset, :snapshot_at, :not_changed) do
        :not_changed -> {:ok, asciicast}
        _ -> update_snapshot(asciicast)
      end
    end
  end

  def delete_asciicast(asciicast) do
    with {:ok, asciicast} <- Repo.delete(asciicast) do
      delete_files(asciicast)
      {:ok, asciicast}
    end
  end

  defp delete_files(asciicast) do
    for f <- [:file, :stdout_data, :stdout_timing, :stdout_frames] do
      if path = Asciicast.file_store_path(asciicast, f) do
        :ok = FileStore.delete_file(path)
      end
    end

    :ok
  end

  def update_snapshot(%Asciicast{terminal_columns: w, terminal_lines: h} = asciicast) do
    secs = Asciicast.snapshot_at(asciicast)
    snapshot = asciicast |> stdout_stream |> generate_snapshot(w, h, secs)
    asciicast |> Asciicast.snapshot_changeset(snapshot) |> Repo.update()
  end

  def generate_snapshot(stdout_stream, width, height, secs) do
    frames = Stream.take_while(stdout_stream, &frame_before_or_at?(&1, secs))

    {:ok, %{"lines" => lines, "cursor" => cursor}} =
      Vt.with_vt(width, height, fn vt ->
        Enum.each(frames, fn {_, text} -> Vt.feed(vt, text) end)
        Vt.dump_screen(vt, 30_000)
      end)

    case cursor do
      %{"visible" => true, "x" => x, "y" => y} ->
        lines
        |> AsciinemaWeb.AsciicastView.split_chunks()
        |> List.update_at(y, fn line ->
          List.update_at(line, x, fn {text, attrs} ->
            attrs = Map.put(attrs, "inverse", !(attrs["inverse"] || false))
            {text, attrs}
          end)
        end)
        |> AsciinemaWeb.AsciicastView.group_chunks()
        |> Enum.map(fn chunks ->
          Enum.map(chunks, &Tuple.to_list/1)
        end)

      _ ->
        lines
    end
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

  def asciicast_file_path(asciicast) do
    Asciicast.json_store_path(asciicast)
  end

  def inc_views_count(asciicast) do
    from(a in Asciicast, where: a.id == ^asciicast.id)
    |> Repo.update_all(inc: [views_count: 1])
  end

  def upgrade do
    from(a in Asciicast, where: a.version == 0)
    |> Repo.all()
    |> Enum.each(&upgrade/1)
  end

  def upgrade(%Asciicast{version: 0} = asciicast) do
    Logger.info("upgrading asciicast ##{asciicast.id} from version 0 to version 2...")

    header = v2_header(asciicast)

    v2_path =
      asciicast
      |> stdout_stream()
      |> write_v2_file(header)

    upload = %Plug.Upload{path: v2_path, content_type: "application/octet-stream"}

    changeset =
      Changeset.change(
        asciicast, version: 2, file: "0.cast", stdout_frames: nil
      )

    changeset
    |> Changeset.apply_changes()
    |> save_file({:file, upload, true})

    {:ok, asciicast_v2} = Repo.update(changeset)

    delete_file(asciicast, :stdout_frames)

    {:ok, asciicast_v2}
  end

  def upgrade(%Asciicast{} = asciicast) do
    {:ok, asciicast}
  end

  defp v2_header(asciicast) do
    header = %{
      width: asciicast.terminal_columns,
      height: asciicast.terminal_lines,
      timestamp: asciicast.created_at |> Timex.to_unix(),
      duration: asciicast.duration,
      title: asciicast.title,
      command: asciicast.command,
      env: %{"TERM" => asciicast.terminal_type, "SHELL" => asciicast.shell}
    }

    header |> Enum.filter(fn {_k, v} -> v end) |> Enum.into(%{})
  end

  def write_v2_file(stdout_stream, %{width: _, height: _} = header) do
    {:ok, tmp_path} = Briefly.create()
    header = Map.put(header, :version, 2)

    File.open!(tmp_path, [:write, :utf8], fn f ->
      :ok = IO.write(f, "#{Poison.encode!(header, pretty: false)}\n")

      for {t, s} <- stdout_stream do
        event = [t, "o", s]
        :ok = IO.write(f, "#{Poison.encode!(event, pretty: false)}\n")
      end
    end)

    tmp_path
  end

  def gc_days do
    Application.get_env(:asciinema, :asciicast_gc_days)
  end

  def archive_asciicasts(users_query, dt) do
    query = from a in Asciicast,
      join: u in ^users_query,
      on: a.user_id == u.id,
      where: a.archivable and is_nil(a.archived_at) and a.created_at < ^dt

    {count, _} = Repo.update_all(query, set: [archived_at: Timex.now()])
    count
  end
end
