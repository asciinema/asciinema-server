defmodule Asciinema.Asciicasts do
  alias Asciinema.{Repo, Asciicast, FileStore}

  def create_asciicast(user, %Plug.Upload{path: path, filename: filename} = upload) do
    with {:ok, json} <- File.read(path),
         {:ok, attrs} <- Poison.decode(json),
         {:ok, attrs} <- extract_attrs(attrs),
         changeset = Asciicast.changeset(%Asciicast{user_id: user.id, file: filename}, attrs),
         {:ok, %Asciicast{} = asciicast} <- Repo.insert(changeset) do
      put_file(asciicast, upload)
      {:ok, asciicast}
    end
  end

  defp extract_attrs(attrs) do
    attrs = %{version: attrs["version"],
              duration: attrs["duration"],
              terminal_columns: attrs["width"],
              terminal_lines: attrs["height"],
              secret_token: "v3ry-sekr1t"} # TODO: move to changeset
    {:ok, attrs}
  end

  defp put_file(asciicast, %{path: tmp_file_path, content_type: content_type}) do
    file_store_path = Asciicast.json_store_path(asciicast)
    :ok = FileStore.put_file(file_store_path, tmp_file_path, content_type)
  end
end
