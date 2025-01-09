defmodule Asciinema.Recordings do
  require Logger
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Asciinema.{FileStore, Fonts, Repo, Themes, Vt}

  alias Asciinema.Recordings.{
    Asciicast,
    Markers,
    Paths,
    Snapshot,
    SnapshotUpdater,
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

  def list_public_asciicasts(%{asciicasts: _} = owner, limit \\ 4) do
    owner
    |> Ecto.assoc(:asciicasts)
    |> filter(:public)
    |> sort(:random)
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  def list_other_public_asciicasts(asciicast, limit \\ 4) do
    Asciicast
    |> filter({asciicast.user_id, :public})
    |> where([a], a.id != ^asciicast.id)
    |> sort(:random)
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  defp filter(q, filters) do
    q
    |> where([a], is_nil(a.archived_at))
    |> do_filter(filters)
  end

  defp do_filter(q, {user_id, f}) do
    q
    |> where([a], a.user_id == ^user_id)
    |> do_filter(f)
  end

  defp do_filter(q, f) do
    case f do
      :featured ->
        where(q, [a], a.featured == true and a.visibility == :public)

      :public ->
        where(q, [a], a.visibility == :public)

      :all ->
        q
    end
  end

  defp sort(q, order) do
    case order do
      :date -> order_by(q, desc: :id)
      :popularity -> order_by(q, desc: :views_count)
      :random -> order_by(q, fragment("RANDOM()"))
    end
  end

  def paginate_asciicasts(filters, order, page, page_size) do
    from(Asciicast)
    |> filter(filters)
    |> sort(order)
    |> preload(:user)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def count_featured_asciicasts do
    from(Asciicast)
    |> filter(:featured)
    |> Repo.count()
  end

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

  def create_asciicast(user, upload, overrides \\ %{})

  def create_asciicast(user, %Plug.Upload{filename: filename} = upload, overrides) do
    changeset =
      change(
        %Asciicast{
          user_id: user.id,
          filename: filename,
          visibility: user.default_asciicast_visibility,
          secret_token: Crypto.random_token(25)
        },
        overrides
      )

    with {:ok, metadata} <- extract_metadata(upload),
         changeset = apply_metadata(changeset, metadata, user.theme_prefer_original),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, upload) do
      if asciicast.snapshot == nil do
        :ok = SnapshotUpdater.update_snapshot(asciicast)
      end

      {:ok, asciicast}
    end
  end

  defp extract_metadata(%{"version" => 0} = attrs) do
    attrs = %{
      version: 0,
      cols: get_in(attrs, ["term", "columns"]),
      rows: get_in(attrs, ["term", "lines"]),
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
        Logger.warn("error extracting v1 metadata: #{inspect(otherwise)}")
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
        Logger.warn("error extracting v2 metadata: #{inspect(otherwise)}")
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
    {_, result} =
      Repo.transaction(fn ->
        case Repo.insert(changeset) do
          {:ok, asciicast} ->
            path = Paths.sharded_path(asciicast)

            asciicast =
              asciicast
              |> Changeset.change(path: path)
              |> Repo.update!()

            save_file(path, file)

            {:ok, asciicast}

          otherwise ->
            otherwise
        end
      end)

    result
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
    |> Snapshot.new()
    |> Snapshot.unwrap()
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

  def asciicast_file_path(asciicast), do: asciicast.path

  def inc_views_count(asciicast) do
    from(a in Asciicast, where: a.id == ^asciicast.id)
    |> Repo.update_all(inc: [views_count: 1])
  end

  def upgradable do
    from(a in Asciicast, where: a.version == 0 or like(a.path, "asciicast/file/%"))
    |> Repo.pages(100)
    |> Stream.flat_map(& &1)
  end

  def upgrade(id) when is_integer(id) do
    id
    |> get_asciicast()
    |> upgrade()
  end

  def upgrade(%Asciicast{} = asciicast) do
    asciicast
    |> upgrade_from_v0()
    |> upgrade_file_path()
  end

  defp upgrade_from_v0(%Asciicast{version: 0} = asciicast) do
    Logger.info("upgrading asciicast ##{asciicast.id} from version 0 to version 2...")

    header = v2_header(asciicast)

    v2_path =
      asciicast
      |> EventStream.new()
      |> EventStream.output()
      |> write_v2_file(header)

    upload = %Plug.Upload{path: v2_path, content_type: "application/octet-stream"}
    path = Paths.sharded_path(%{asciicast | version: 2})

    changeset =
      Changeset.change(asciicast,
        version: 2,
        filename: "0.cast",
        path: path
      )

    save_file(path, upload)

    Repo.update!(changeset)
  end

  defp upgrade_from_v0(asciicast), do: asciicast

  defp upgrade_file_path(%Asciicast{path: "asciicast/file/" <> _ = old_path} = asciicast) do
    Logger.info("upgrading asciicast ##{asciicast.id} file path...")

    {:ok, asciicast} =
      Repo.transaction(fn ->
        new_path = Paths.sharded_path(asciicast)
        asciicast = Repo.update!(Changeset.change(asciicast, path: new_path))
        :ok = FileStore.move_file(old_path, new_path)

        asciicast
      end)

    asciicast
  end

  defp upgrade_file_path(asciicast), do: asciicast

  defp v2_header(asciicast) do
    header = %{
      width: asciicast.cols,
      height: asciicast.rows,
      timestamp: asciicast.inserted_at |> Timex.to_unix(),
      duration: asciicast.duration,
      title: asciicast.title,
      command: asciicast.command,
      env: %{"TERM" => asciicast.terminal_type, "SHELL" => asciicast.shell}
    }

    header |> Enum.filter(fn {_k, v} -> v end) |> Enum.into(%{})
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
