defmodule Asciinema.FileCache do
  def full_path(namespace, path, generator) do
    path = full_path(namespace, path)

    case File.stat(path) do
      {:ok, _} ->
        path

      {:error, :enoent} ->
        content = generator.()
        parent_dir = Path.dirname(path)
        :ok = File.mkdir_p(parent_dir)
        File.write!(path, content)

        path
    end
  end

  defp full_path(namespace, path), do: Path.join([base_path(), to_string(namespace), path])

  defp base_path do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :path)
  end
end
