defmodule Asciinema.Recordings do
  require Logger
  import Ecto, only: [build_assoc: 2]
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Asciinema.{FileStore, Fonts, Repo, Themes, Vt}
  alias Asciinema.Workers.{MigrateRecordingFiles, UpdateSnapshot}

  alias Asciinema.Recordings.{
    Asciicast,
    Markers,
    Paths,
    EventStream,
    Text
  }

  alias Ecto.Changeset

  def fetch_asciicast(id) do
    case get_asciicast(id) do
      nil -> {:error, :not_found}
      asciicast -> {:ok, asciicast}
    end
  end

  def get_asciicast(id) when is_integer(id) do
    Asciicast
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  def get_asciicast(thing) when is_binary(thing) do
    q =
      if String.length(thing) == 25 do
        from(a in Asciicast, where: a.secret_token == ^thing)
      else
        case Integer.parse(thing) do
          {id, ""} ->
            from(a in Asciicast, where: a.visibility == :public and a.id == ^id)

          _ ->
            from(a in Asciicast, where: false)
        end
      end

    q
    |> Repo.one()
    |> Repo.preload(:user)
  end

  def query(filters \\ [], order \\ nil)

  def query(filters, order) do
    from(Asciicast)
    |> where([a], is_nil(a.archived_at))
    |> apply_filters(filters)
    |> sort(order)
  end

  defp apply_filters(q, filters) when is_list(filters) do
    filters = Enum.uniq(filters)

    Enum.reduce(filters, q, &apply_filter/2)
  end

  defp apply_filters(q, filter), do: apply_filters(q, List.wrap(filter))

  defp apply_filter(filter, q) do
    case filter do
      {:id, {:not_eq, id}} ->
        where(q, [a], a.id != ^id)

      {:user_id, user_id} ->
        where(q, [a], a.user_id == ^user_id)

      {:stream_id, stream_id} when is_integer(stream_id) ->
        where(q, [a], a.stream_id == ^stream_id)

      {:stream_id, {:not_eq, stream_id}} ->
        where(q, [a], is_nil(a.stream_id) or a.stream_id != ^stream_id)

      :featured ->
        where(q, [a], a.featured == true and a.visibility == :public)

      :public ->
        where(q, [a], a.visibility == :public)
    end
  end

  defp sort(q, nil), do: q

  defp sort(q, order) do
    case order do
      :date -> order_by(q, desc: :id)
      :popularity -> order_by(q, desc: :views_count)
      :random -> order_by(q, fragment("RANDOM()"))
    end
  end

  def paginate(%Ecto.Query{} = query, page, page_size) do
    query
    |> preload(:user)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def list(q, limit) do
    q
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  def count(q), do: Repo.count(q)

  def ensure_welcome_asciicast(user) do
    if Repo.count(Ecto.assoc(user, :asciicasts)) == 0 do
      cast_path = Path.join(:code.priv_dir(:asciinema), "welcome.cast")

      upload = %Plug.Upload{
        path: cast_path,
        filename: "ascii.cast",
        content_type: "application/octet-stream"
      }

      {:ok, _} =
        create_asciicast(user, upload, %{
          visibility: :public,
          snapshot_at: 106.0
        })
    end

    :ok
  end

  def create_asciicast(user, %Plug.Upload{filename: filename} = upload, fields \\ %{}) do
    attrs =
      Map.merge(
        %{
          filename: filename,
          visibility: user.default_asciicast_visibility,
          secret_token: Crypto.random_token(25)
        },
        fields
      )

    changeset =
      user
      |> build_assoc(:asciicasts)
      |> change(attrs)

    with {:ok, metadata} <- extract_metadata(upload),
         changeset = apply_metadata(changeset, metadata, user.theme_prefer_original),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, upload) do
      if asciicast.snapshot == nil do
        %{asciicast_id: asciicast.id}
        |> UpdateSnapshot.new()
        |> Oban.insert!()
      end

      {:ok, asciicast}
    end
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
        cols: attrs["width"],
        rows: attrs["height"],
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
        Logger.warning("error extracting v1 metadata: #{inspect(otherwise)}")
        {:error, :unknown_format}
    end
  end

  defp extract_v2_metadata(path) do
    with {:ok, line} when is_binary(line) <- File.open(path, fn f -> IO.read(f, :line) end),
         {:ok, %{"version" => 2} = header} <- decode_json(line) do
      metadata = %{
        version: 2,
        cols: header["width"],
        rows: header["height"],
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
        Logger.warning("error extracting v2 metadata: #{inspect(otherwise)}")
        {:error, :unknown_format}
    end
  end

  defp get_v2_duration(path) do
    path
    |> EventStream.new()
    |> EventStream.duration()
  end

  @hex_color_re ~r/^#[0-9a-f]{6}$/
  @hex_palette_re ~r/^(#[0-9a-f]{6}:){7}((#[0-9a-f]{6}:){8})?#[0-9a-f]{6}$/

  defp apply_metadata(changeset, metadata, prefer_original_theme) do
    theme_name = if metadata[:theme_palette] && prefer_original_theme, do: "original"

    changeset
    |> put_change(:version, metadata.version)
    |> put_change(:theme_name, theme_name)
    |> cast(metadata, [
      :duration,
      :cols,
      :rows,
      :terminal_type,
      :command,
      :shell,
      :uname,
      :recorded_at,
      :theme_fg,
      :theme_bg,
      :theme_palette,
      :idle_time_limit,
      :title
    ])
    |> validate_required([:duration, :cols, :rows])
    |> validate_format(:theme_fg, @hex_color_re)
    |> validate_format(:theme_bg, @hex_color_re)
    |> validate_format(:theme_palette, @hex_palette_re)
  end

  defp decode_json(json) do
    case Jason.decode(json) do
      {:ok, thing} -> {:ok, thing}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid}
    end
  end

  defp do_create_asciicast(changeset, file) do
    Repo.transact(fn ->
      with {:ok, asciicast} <- Repo.insert(changeset) do
        asciicast = assign_path(asciicast)
        save_file(asciicast.path, file)

        {:ok, asciicast}
      end
    end)
  end

  def assign_path(asciicast) do
    asciicast = Repo.preload(asciicast, :user)
    path = Paths.path(asciicast)

    asciicast
    |> Changeset.change(path: path)
    |> Repo.update!()
  end

  defp save_file(path, %{path: tmp_path, content_type: content_type}) do
    :ok = FileStore.put_file(path, tmp_path, content_type)
  end

  def change_asciicast(asciicast, attrs \\ %{}) do
    asciicast
    |> cast(attrs, [
      :visibility,
      :title,
      :description,
      :cols_override,
      :rows_override,
      :theme_name,
      :idle_time_limit,
      :speed,
      :snapshot_at,
      :terminal_line_height,
      :terminal_font_family,
      :markers
    ])
    |> validate_number(:cols_override, greater_than: 0, less_than: 1024)
    |> validate_number(:rows_override, greater_than: 0, less_than: 512)
    |> validate_number(:idle_time_limit, greater_than_or_equal_to: 0.5)
    |> validate_inclusion(:theme_name, Themes.terminal_themes() ++ ["original"])
    |> validate_number(:terminal_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:terminal_font_family, Fonts.terminal_font_families())
    |> validate_number(:snapshot_at, greater_than: 0)
    |> validate_change(:markers, &Markers.validate/2)
  end

  def update_asciicast(asciicast, attrs \\ %{}) do
    changeset = change_asciicast(asciicast, attrs)

    with {:ok, asciicast} <- Repo.update(changeset) do
      if stale_snapshot?(changeset) do
        update_snapshot(asciicast)
      else
        {:ok, asciicast}
      end
    end
  end

  defp stale_snapshot?(changeset) do
    changed?(changeset, :snapshot_at) ||
      changed?(changeset, :cols_override) ||
      changed?(changeset, :rows_override)
  end

  def set_featured(asciicast, featured \\ true) do
    asciicast
    |> Changeset.change(%{featured: featured})
    |> Repo.update!()
  end

  def delete_asciicast(asciicast) do
    with {:ok, asciicast} <- Repo.delete(asciicast) do
      case FileStore.delete_file(asciicast.path) do
        :ok -> {:ok, asciicast}
        {:error, :enoent} -> {:ok, asciicast}
        otherwise -> otherwise
      end
    end
  end

  def delete_asciicasts(%{asciicasts: _} = owner) do
    delete_asciicasts(Ecto.assoc(owner, :asciicasts))
  end

  def delete_asciicasts(%Ecto.Query{} = query) do
    asciicasts = Repo.all(query)

    for a <- asciicasts do
      {:ok, _} = delete_asciicast(a)
    end

    length(asciicasts)
  end

  def update_snapshot(%Asciicast{} = asciicast) do
    cols = asciicast.cols_override || asciicast.cols
    rows = asciicast.rows_override || asciicast.rows
    secs = asciicast.snapshot_at || asciicast.duration / 2

    snapshot =
      asciicast
      |> EventStream.new()
      |> EventStream.output()
      |> generate_snapshot(cols, rows, secs)

    asciicast
    |> Changeset.cast(%{snapshot: snapshot}, [:snapshot])
    |> Repo.update()
  end

  def generate_snapshot(output_stream, cols, rows, secs) do
    frames = Stream.take_while(output_stream, &frame_before_or_at?(&1, secs))

    {:ok, {lines, cursor}} =
      Vt.with_vt(cols, rows, [scrollback_limit: 0], fn vt ->
        Enum.each(frames, fn {_, text} -> Vt.feed(vt, text) end)

        Vt.dump_screen(vt)
      end)

    {lines, cursor}
  end

  def title(asciicast) do
    cond do
      asciicast.title not in [nil, ""] ->
        asciicast.title

      asciicast.command not in [nil, ""] && asciicast.command != asciicast.shell ->
        asciicast.command

      true ->
        "untitled"
    end
  end

  defdelegate text(asciicast), to: Text
  defdelegate text_file_path(asciicast), to: Text

  defp frame_before_or_at?({time, _}, secs) do
    time <= secs
  end

  def inc_views_count(asciicast) do
    from(a in Asciicast, where: a.id == ^asciicast.id)
    |> Repo.update_all(inc: [views_count: 1])
  end

  def stream_migratable_asciicasts do
    from(a in Asciicast, preload: :user)
    |> stream_asciicasts()
    |> Stream.filter(&stale_path?/1)
  end

  def stream_migratable_asciicasts(user_id) do
    from(a in Asciicast, where: a.user_id == ^user_id, preload: :user)
    |> stream_asciicasts()
    |> Stream.filter(&stale_path?/1)
  end

  defp stream_asciicasts(query) do
    query
    |> Repo.pages(100)
    |> Stream.flat_map(& &1)
  end

  defp stale_path?(asciicast) do
    asciicast.path != Paths.path(asciicast)
  end

  def migrate_files(user) do
    %{user_id: user.id}
    |> MigrateRecordingFiles.new()
    |> Oban.insert!()

    :ok
  end

  def migrate_file(id) when is_integer(id) do
    id
    |> get_asciicast()
    |> migrate_file()
  end

  def migrate_file(asciicast) do
    cur_path = asciicast.path
    new_path = Paths.path(asciicast)

    if cur_path != new_path do
      changeset = change(asciicast, path: new_path)

      {:ok, asciicast} =
        Repo.transact(fn ->
          asciicast = Repo.update!(changeset)
          :ok = FileStore.move_file(cur_path, new_path)

          {:ok, asciicast}
        end)

      asciicast
    else
      asciicast
    end
  end

  def write_v2_file(output_stream, %{width: _, height: _} = header) do
    {:ok, tmp_path} = Briefly.create()
    header = Map.put(header, :version, 2)

    File.open!(tmp_path, [:write, :utf8], fn f ->
      :ok = IO.write(f, "#{Jason.encode!(header, pretty: false)}\n")

      for {t, s} <- output_stream do
        event = [t, "o", s]
        :ok = IO.write(f, "#{Jason.encode!(event, pretty: false)}\n")
      end
    end)

    tmp_path
  end

  def hide_unclaimed_asciicasts(tmp_users_query, t) do
    query =
      from a in Asciicast,
        join: u in ^tmp_users_query,
        on: a.user_id == u.id,
        where: a.archivable and is_nil(a.archived_at) and a.inserted_at < ^t

    {count, _} = Repo.update_all(query, set: [archived_at: Timex.now()])

    count
  end

  def delete_unclaimed_asciicasts(tmp_users_query, t) do
    query =
      from a in Asciicast,
        join: u in ^tmp_users_query,
        on: a.user_id == u.id,
        where: a.archivable and a.inserted_at < ^t

    delete_asciicasts(query)
  end

  def reassign_asciicasts(src_user_id, dst_user_id) do
    q = from(a in Asciicast, where: a.user_id == ^src_user_id)
    Repo.update_all(q, set: [user_id: dst_user_id, updated_at: Timex.now()])
  end
end
