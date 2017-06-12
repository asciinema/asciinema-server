defmodule Asciinema.Asciicasts do
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, Asciicast, FileStore}

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

  def create_asciicast(user, %Plug.Upload{path: path, filename: filename} = upload) do
    asciicast = %Asciicast{user_id: user.id,
                           file: filename,
                           private: user.asciicasts_private_by_default}

    {_, result} = Repo.transaction(fn ->
      with {:ok, json} <- File.read(path),
           {:ok, attrs} <- Poison.decode(json),
           {:ok, attrs} <- extract_attrs(attrs),
           changeset = Asciicast.create_changeset(asciicast, attrs),
           {:ok, %Asciicast{} = asciicast} <- Repo.insert(changeset) do
        put_file(asciicast, upload)
        # TODO: generate snapshot and poster
        {:ok, asciicast}
      else
        {:error, :invalid} ->
          {:error, :parse_error}
        otherwise ->
          otherwise
      end
    end)

    result
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

  defp put_file(asciicast, %{path: tmp_file_path, content_type: content_type}) do
    file_store_path = Asciicast.json_store_path(asciicast)
    :ok = FileStore.put_file(file_store_path, tmp_file_path, content_type)
  end
end
