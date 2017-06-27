defmodule Asciinema.Asciicasts do
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, Asciicast, FileStore}
  alias Asciinema.Asciicasts.PosterGenerator

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

  def create_asciicast(user, params, user_agent \\ nil)

  def create_asciicast(user, %Plug.Upload{path: path, filename: filename} = upload, user_agent) do
    asciicast = %Asciicast{user_id: user.id,
                           user_agent: user_agent,
                           file: filename,
                           private: user.asciicasts_private_by_default}

    files = [{:file, upload}]

    with {:ok, json} <- File.read(path),
         {:ok, attrs} <- Poison.decode(json),
         {:ok, attrs} <- extract_attrs(attrs),
         changeset = Asciicast.create_changeset(asciicast, attrs),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, files) do
      generate_poster(asciicast)
      {:ok, asciicast}
    else
      {:error, :invalid} ->
        {:error, :parse_error}
      otherwise ->
        otherwise
    end
  end

  def create_asciicast(user, %{"meta" => attrs,
                               "stdout" => %Plug.Upload{} = data,
                               "stdout_timing" => %Plug.Upload{} = timing}, user_agent) do
    asciicast = %Asciicast{user_id: user.id,
                           user_agent: unless(attrs["uname"], do: user_agent),
                           stdout_data: data.filename,
                           stdout_timing: timing.filename,
                           private: user.asciicasts_private_by_default}

    attrs = Map.put(attrs, "version", 0)
    changeset = Asciicast.create_changeset(asciicast, attrs)
    files = [{:stdout_data, data}, {:stdout_timing, timing}]

    case do_create_asciicast(changeset, files) do
      {:ok, %Asciicast{} = asciicast} ->
        generate_poster(asciicast)
        {:ok, asciicast}
      otherwise ->
        otherwise
    end
  end

  defp extract_attrs(%{"version" => 1} = attrs) do
    attrs = %{version: attrs["version"],
              duration: attrs["duration"],
              terminal_columns: attrs["width"],
              terminal_lines: attrs["height"],
              terminal_type: get_in(attrs, ["env", "TERM"]),
              command: attrs["command"],
              shell: get_in(attrs, ["env", "SHELL"]),
              title: attrs["title"]}
    {:ok, attrs}
  end
  defp extract_attrs(_attrs) do
    {:error, :unknown_format}
  end

  defp do_create_asciicast(changeset, files) do
    {_, result} = Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, %Asciicast{} = asciicast} ->
          Enum.each(files, fn {type, upload} -> save_file(asciicast, type, upload) end)
          {:ok, asciicast}
        otherwise ->
          otherwise
      end
    end)

    result
  end

  defp save_file(asciicast, type, %{path: tmp_file_path, content_type: content_type}) do
    file_store_path = Asciicast.file_store_path(asciicast, type)
    :ok = FileStore.put_file(file_store_path, tmp_file_path, content_type)
  end

  defp generate_poster(asciicast) do
    PosterGenerator.generate(asciicast)
  end
end
