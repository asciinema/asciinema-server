defmodule Asciinema.Recordings do
  require Logger
  import Ecto, only: [build_assoc: 2]
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Asciinema.Recordings.Asciicast.{V1, V2, V3}
  alias Asciinema.{FileStore, Fonts, Repo, Themes, Vt}
  alias Asciinema.Workers.{MigrateRecordingFiles, UpdateSnapshot}

  alias Asciinema.Recordings.{
    Asciicast,
    Markers,
    Paths,
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

      {:stream_id, {:in, stream_ids}} ->
        where(q, [a], a.stream_id in ^stream_ids)

      :featured ->
        where(q, [a], a.featured == true and a.visibility == :public)

      :public ->
        where(q, [a], a.visibility == :public)

      :snapshotless ->
        where(q, [a], is_nil(a.snapshot))
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

  def stream(%Ecto.Query{} = query) do
    query
    |> preload(:user)
    |> Repo.pages(100)
    |> Stream.flat_map(& &1)
  end

  def count(q), do: Repo.count(q)

  def count_by(q, field) do
    from(a in q, group_by: field(a, ^field), select: {field(a, ^field), count(a.id)})
    |> Repo.all()
    |> Enum.into(%{})
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

  def create_asciicast(user, %Plug.Upload{filename: filename} = upload, fields \\ %{}) do
    attrs =
      Map.merge(
        %{
          filename: filename,
          visibility: user.default_recording_visibility,
          secret_token: Crypto.random_token(25)
        },
        fields
      )

    changeset =
      user
      |> build_assoc(:asciicasts)
      |> change(attrs)

    with {:ok, metadata} <- extract_metadata(upload),
         changeset = apply_metadata(changeset, metadata, user.term_theme_prefer_original),
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
    case V2.fetch_metadata(path) do
      {:ok, metadata} -> {:ok, metadata}
      {:error, {:invalid_version, 3}} -> V3.fetch_metadata(path)
      {:error, :invalid_format} -> V1.fetch_metadata(path)
    end
  end

  @max_term_cols 720
  @max_term_rows 200
  @hex_color_re ~r/^#[0-9a-f]{6}$/
  @hex_palette_re ~r/^(#[0-9a-f]{6}:){7}((#[0-9a-f]{6}:){8})?#[0-9a-f]{6}$/

  defp apply_metadata(changeset, metadata, prefer_original_theme) do
    term_theme_name = if metadata[:term_theme_palette] && prefer_original_theme, do: "original"

    changeset
    |> put_change(:version, metadata.version)
    |> put_change(:term_theme_name, term_theme_name)
    |> cast(metadata, [
      :duration,
      :term_cols,
      :term_rows,
      :term_type,
      :term_version,
      :term_theme_fg,
      :term_theme_bg,
      :term_theme_palette,
      :command,
      :shell,
      :uname,
      :recorded_at,
      :env,
      :idle_time_limit,
      :title
    ])
    |> validate_required([:duration, :term_cols, :term_rows])
    |> validate_number(:term_cols, greater_than: 0, less_than_or_equal_to: @max_term_cols)
    |> validate_number(:term_rows, greater_than: 0, less_than_or_equal_to: @max_term_rows)
    |> validate_format(:term_theme_fg, @hex_color_re)
    |> validate_format(:term_theme_bg, @hex_color_re)
    |> validate_format(:term_theme_palette, @hex_palette_re)
    |> validate_change(:env, &validate_env/2)
  end

  defp validate_env(:env, env) do
    errors = []

    errors =
      if Enum.all?(Map.keys(env), &String.match?(&1, ~r/^[A-Z0-9_]+$/)) do
        errors
      else
        [{:env, "must include valid env var names"} | errors]
      end

    errors =
      if Enum.all?(Map.values(env), &is_binary/1) do
        errors
      else
        [{:env, "must include only string values"} | errors]
      end

    errors
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
      :term_cols_override,
      :term_rows_override,
      :term_theme_name,
      :term_line_height,
      :term_font_family,
      :idle_time_limit,
      :speed,
      :snapshot_at,
      :markers
    ])
    |> validate_number(:term_cols_override,
      greater_than: 0,
      less_than_or_equal_to: @max_term_cols
    )
    |> validate_number(:term_rows_override,
      greater_than: 0,
      less_than_or_equal_to: @max_term_rows
    )
    |> validate_number(:idle_time_limit, greater_than_or_equal_to: 0.5)
    |> validate_inclusion(:term_theme_name, Themes.terminal_themes() ++ ["original"])
    |> validate_number(:term_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
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
      changed?(changeset, :term_cols_override) ||
      changed?(changeset, :term_rows_override)
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
    cols = asciicast.term_cols_override || asciicast.term_cols
    rows = asciicast.term_rows_override || asciicast.term_rows
    secs = asciicast.snapshot_at || asciicast.duration / 2

    snapshot =
      asciicast
      |> event_stream()
      |> output()
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

  def event_stream(%Asciicast{} = asciicast) do
    {:ok, local_tmp_path} = Briefly.create()
    :ok = FileStore.download_file(asciicast.path, local_tmp_path)

    case asciicast.version do
      1 -> V1.event_stream(local_tmp_path)
      2 -> V2.event_stream(local_tmp_path)
      3 -> V3.event_stream(local_tmp_path)
    end
  end

  def output(stream) do
    stream
    |> Stream.filter(fn {_, code, _} -> code == "o" end)
    |> Stream.map(fn {time, _, data} -> {time, data} end)
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

  def migratable(stream), do: Stream.filter(stream, &stale_path?/1)

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
